# @summary Installs and manages the OpenVox GUI web console.
#
# Clones cvquesty/openvox-gui at a pinned release tag, pre-builds the React
# frontend, and drives the upstream installer (install.sh) in unattended mode.
# Runs alongside profile::openvoxview: OpenVoxView is a read-only reports
# browser (port 5000) while the GUI is a management console (port 4567) with
# CA, orchestration, and PQL features.
#
# The GUI's own ENC, firewall, and package-mirror features are deliberately
# disabled in install.conf: this repo classifies nodes via roles in site
# manifests, manages the firewall with puppetlabs/firewall, and needs no agent
# package mirror on a dev VM.
#
# @param version
#   Release of openvox-gui to install (git tag without the leading 'v').
# @param admin_password
#   Password for the initial admin user.
# @param app_port
#   Port the web interface listens on.
#
# @example
#   include profile::openvox_gui
class profile::openvox_gui (
  String  $version,
  String  $admin_password,
  Integer $app_port = 4567,
) {
  $src_dir     = '/opt/openvox-gui-src'
  $install_dir = '/opt/openvox-gui'

  # Build/install prerequisites. EL10's AppStream ships Node.js >= 20 and
  # Python >= 3.12 directly, so unlike EL9 there is no dnf module stream to
  # switch (DNF5 dropped modularity) and no python alternatives juggling.
  package { ['git', 'nodejs', 'npm']:
    ensure => present,
  }

  vcsrepo { $src_dir:
    ensure   => present,
    provider => git,
    source   => 'https://github.com/cvquesty/openvox-gui.git',
    revision => "v${version}",
    require  => Package['git'],
  }

  # Pre-build the React frontend in the source checkout. install.sh's own
  # build path is unusable here: on aarch64 a two-step npm install is needed
  # for the rollup native binding (https://github.com/npm/cli/issues/4828),
  # and its Node.js bootstrap uses dnf modules, which fail on EL10. With
  # BUILD_FRONTEND=false the installer copies the pre-built dist/ instead.
  # The script stamps frontend/.built-version so the build re-runs only when
  # the checked-out VERSION changes (i.e. on version bumps).
  file { "${src_dir}/build-frontend.sh":
    ensure  => file,
    mode    => '0755',
    source  => 'puppet:///modules/profile/openvox_gui/build-frontend.sh',
    require => Vcsrepo[$src_dir],
  }

  exec { 'build openvox-gui frontend':
    command => "/bin/bash ${src_dir}/build-frontend.sh",
    unless  => "/usr/bin/cmp -s ${src_dir}/VERSION ${src_dir}/frontend/.built-version",
    require => [
      File["${src_dir}/build-frontend.sh"],
      Package['nodejs'],
      Package['npm'],
    ],
    timeout => 600,
  }

  # Configuration for the unattended installer run (install.sh -c).
  file { "${src_dir}/install.conf":
    ensure  => file,
    mode    => '0600',
    content => epp('profile/openvox_gui/install.conf.epp', {
      'app_port'       => $app_port,
      'admin_password' => $admin_password,
    }),
    require => Vcsrepo[$src_dir],
  }

  # Run the installer. The credentials file only exists after a fully
  # successful install, and the VERSION comparison re-runs the installer when
  # the pinned release changes, giving an upgrade path. The installer suggests
  # deleting config/.credentials after noting the password -- don't: Puppet
  # uses it as the install-complete marker, and the same password already sits
  # in install.conf and config/.env anyway. Note the installer's final health
  # check can race a slow first service start and fail the exec even though
  # the install completed; the next run converges via this guard.
  exec { 'install openvox-gui':
    command => '/bin/bash install.sh -c install.conf',
    cwd     => $src_dir,
    unless  => "/bin/bash -c 'test -f ${install_dir}/config/.credentials && cmp -s ${src_dir}/VERSION ${install_dir}/VERSION'",
    require => [
      File["${src_dir}/install.conf"],
      Exec['build openvox-gui frontend'],
    ],
    timeout => 900,
  }

  # The installer writes /etc/sudoers.d/openvox-gui-users (~50 rules for CA,
  # Bolt, r10k, and log access). profile::base's sudo class purges unmanaged
  # sudoers.d content, so the node's hiera sets sudo::purge_ignore to leave
  # that installer-owned file alone (see data/nodes/puppet.example.com.yaml).

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
