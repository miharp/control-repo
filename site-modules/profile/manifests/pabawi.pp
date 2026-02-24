# @summary Installs and configures Pabawi on the Puppet master.
#
# Pabawi is a unified web interface for the Puppet ecosystem (Bolt, PuppetDB,
# Puppet Server, Hiera, Ansible). Installs via npm and runs as a systemd service.
#
# @example
#   include profile::pabawi
class profile::pabawi {
  # CentOS Stream 9 ships nodejs 16; pabawi's frontend build (Vite) requires
  # Node.js 20+. Switch to the nodejs:20 module stream before installation.
  exec { 'enable-nodejs-20-module':
    command => 'dnf module switch-to nodejs:20 -y',
    path    => ['/usr/bin', '/usr/sbin'],
    unless  => '/usr/bin/node -e "process.exit(parseInt(process.version.slice(1)) >= 20 ? 0 : 1)" 2>/dev/null',
    before  => Package['nodejs'],
  }

  # Ensure parent directories exist before integrations create cert/ssl subdirs.
  file { '/etc/pabawi':
    ensure => directory,
    before => Class['pabawi'],
  }

  file { '/opt/pabawi/certs':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/opt/pabawi'],
    before  => Class['pabawi'],
  }

  class { 'pabawi':
    install_class => 'pabawi::install::npm',
    proxy_manage  => false,
  }

  # The pabawi module's service unit expects ${install_dir}/bin/pabawi but the
  # npm build outputs to backend/dist/server.js. Create a wrapper entry point.
  file { '/opt/pabawi/app/bin':
    ensure  => directory,
    owner   => 'pabawi',
    group   => 'pabawi',
    mode    => '0755',
    require => Vcsrepo['/opt/pabawi/app'],
  }

  file { '/opt/pabawi/app/bin/pabawi':
    ensure  => file,
    owner   => 'pabawi',
    group   => 'pabawi',
    mode    => '0755',
    content => "import '/opt/pabawi/app/backend/dist/server.js';\n",
    require => File['/opt/pabawi/app/bin'],
    before  => Service['pabawi'],
  }

  # The pabawi module writes .env to backend/.env, but the app's working
  # directory is /opt/pabawi/app and dotenv reads from process.cwd()/.env.
  # Symlink the root .env to the managed backend .env so dotenv finds it.
  file { '/opt/pabawi/app/.env':
    ensure  => link,
    target  => '/opt/pabawi/app/backend/.env',
    require => Vcsrepo['/opt/pabawi/app'],
    notify  => Service['pabawi'],
  }

  # Bind to all interfaces so pabawi is reachable on the private network
  # (the module defaults HOST to localhost/loopback only).
  concat::fragment { 'pabawi_env_host':
    target  => 'pabawi_env_file',
    content => "HOST=0.0.0.0\n",
    order   => '05',
  }

  # Restart pabawi when .env changes (the module doesn't subscribe service to concat).
  Concat['pabawi_env_file'] ~> Service['pabawi']

  # Open firewall port for the pabawi web interface.
  firewall { '200 allow pabawi web interface':
    dport => 3000,
    proto => 'tcp',
    jump  => 'ACCEPT',
  }
}
