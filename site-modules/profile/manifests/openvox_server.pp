# @summary Manages the openvox-server package
#
# Manages the openvox-server package version on the Puppet master.
#
# @param version
#   The version of the openvox-server package to install.
#
# @example
#   include profile::openvox_server
class profile::openvox_server (
  String $version,
) {
  if $facts['os']['family'] == 'RedHat' {
    $package_version = "${version}-1.el${facts['os']['release']['major']}"
  } else {
    $package_version = $version
  }

  package { 'openvox-server':
    ensure => $package_version,
  }

  # Send reports to PuppetDB so they appear in dashboards and reporting tools.
  ini_setting { 'puppetserver reports':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'server',
    setting => 'reports',
    value   => 'store,puppetdb',
    notify  => Service['puppetserver'],
  }

  service { 'puppetserver':
    ensure => running,
    enable => true,
  }
}
