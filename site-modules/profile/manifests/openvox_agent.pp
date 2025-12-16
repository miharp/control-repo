# @summary Installs the openvox-agent package
#
# Installs the openvox-agent package
#
# @param version
#   The version of the openvox-agent package to install.
#
# @example
#   include profile::openvox_agent
class profile::openvox_agent (
  String $version,
) {
  if $facts['os']['family'] == 'RedHat' {
    $package_version = "${version}-1.el${facts['os']['release']['major']}"
  } elsif $facts['os']['name'] == 'Ubuntu' {
    $package_version = "${version}-1+ubuntu${facts['os']['release']['full']}"
  } else {
    $package_version = $version
  }

  package { 'openvox-agent':
    ensure => $package_version,
  }
}
