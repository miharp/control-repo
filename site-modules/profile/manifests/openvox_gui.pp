# @summary Installs and manages the OpenVox GUI web interface
#
# Clones and installs openvox-gui from GitHub on the OpenVox Server.
# After installation, the interface is accessible at https://puppet.example.com:4567.
#
# @param admin_password
#   Password for the initial admin user (stored in /opt/openvox-gui/config/.credentials).
# @param app_port
#   Port the web interface listens on. Default: 4567.
#
# @example
#   include profile::openvox_gui
class profile::openvox_gui (
  String  $admin_password,
  Integer $app_port = 4567,
) {
  # Prerequisites declared as prerequisites by the upstream installer
  package { ['git', 'python3.11']:
    ensure => present,
  }

  # The install.sh venv is created via `python3`, which defaults to 3.9 on CS9.
  # Register 3.11 in alternatives so `python3` resolves to it before the install runs.
  exec { 'register python3.11 alternative':
    command => '/usr/sbin/alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 311',
    unless  => '/usr/sbin/alternatives --display python3 2>/dev/null | /usr/bin/grep -q python3.11',
    require => Package['python3.11'],
  }

  exec { 'set python3 to 3.11':
    command => '/usr/sbin/alternatives --set python3 /usr/bin/python3.11',
    unless  => '/bin/bash -c "/usr/bin/python3 --version 2>&1 | /usr/bin/grep -q Python\\ 3.11"',
    require => Exec['register python3.11 alternative'],
  }

  # Node.js 20+ is required to build the React 18 frontend.
  # CentOS Stream 9 defaults to nodejs:16 so we must switch streams first.
  exec { 'switch to nodejs:20':
    command => '/usr/bin/dnf module switch-to nodejs:20 -y',
    unless  => '/bin/bash -c "/usr/bin/dnf module list --enabled nodejs 2>/dev/null | /usr/bin/grep -q \"20 \[e\]\""',
  }

  package { 'nodejs':
    ensure  => present,
    require => Exec['switch to nodejs:20'],
  }

  # Clone the repository to a staging directory
  exec { 'clone openvox-gui':
    command => '/usr/bin/git clone https://github.com/cvquesty/openvox-gui.git /opt/openvox-gui-src',
    creates => '/opt/openvox-gui-src',
    require => Package['git'],
  }

  # Pre-build the React frontend in the source directory.
  # install.sh has an npm bug on ARM64 (https://github.com/npm/cli/issues/4828):
  # it runs `npm install` then immediately `npm run build`, but the ARM64 rollup
  # native binding is missing from the first install. The fix is a two-step install:
  # first `npm install`, then explicitly add @rollup/rollup-linux-arm64-gnu, then build.
  # With BUILD_FRONTEND=false in install.conf, the installer expects dist/ to already
  # exist (copied from source in step 3), so we pre-build here.
  file { '/opt/openvox-gui-src/build-frontend.sh':
    ensure  => file,
    mode    => '0755',
    source  => 'puppet:///modules/profile/openvox_gui/build-frontend.sh',
    require => Exec['clone openvox-gui'],
  }

  exec { 'build openvox-gui frontend':
    command => '/bin/bash /opt/openvox-gui-src/build-frontend.sh',
    creates => '/opt/openvox-gui-src/frontend/dist',
    require => [
      File['/opt/openvox-gui-src/build-frontend.sh'],
      Package['nodejs'],
    ],
    timeout => 300,
  }

  # Configuration file for unattended installation (-c flag).
  # BUILD_FRONTEND=false because we pre-build above and the installer copies dist/.
  file { '/opt/openvox-gui-src/install.conf':
    ensure  => file,
    content => epp('profile/openvox_gui/install.conf.epp', {
      'app_port'       => $app_port,
      'admin_password' => $admin_password,
    }),
    require => Exec['clone openvox-gui'],
  }

  # Run the installer. Idempotent via 'creates' pointing at the credentials file,
  # which only exists after a fully successful install.
  exec { 'install openvox-gui':
    command => '/bin/bash install.sh -c install.conf',
    cwd     => '/opt/openvox-gui-src',
    creates => '/opt/openvox-gui/config/.credentials',
    require => [
      File['/opt/openvox-gui-src/install.conf'],
      Exec['build openvox-gui frontend'],
      Exec['set python3 to 3.11'],
    ],
    timeout => 600,
  }

  # Manage the sudoers rules the installer creates so the sudo class doesn't purge them.
  sudo::conf { 'openvox-gui':
    source  => 'puppet:///modules/profile/openvox_gui/sudoers-openvox-gui',
    require => Exec['install openvox-gui'],
  }

  service { 'openvox-gui':
    ensure  => running,
    enable  => true,
    require => Exec['install openvox-gui'],
  }

  firewall { "200 allow openvox-gui port ${app_port}":
    dport => $app_port,
    proto => 'tcp',
    jump  => 'ACCEPT',
  }
}
