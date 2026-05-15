# @summary Manages the openvox-server package
#
# Manages the openvox-server package version on the Puppet master.
#
# @param version
#   The version of the openvox-server package to install.
# @param source
#   Optional direct URL to an RPM. When set, installs from the URL instead of
#   a repo, and $version is used as-is for the ensure value (no el-suffix is
#   appended). Intended for pre-release/snapshot testing.
#
# @example
#   include profile::openvox_server
class profile::openvox_server (
  String $version,
  Optional[String] $source = undef,
) {
  if $source {
    package { 'openvox-server':
      ensure   => $version,
      source   => $source,
      provider => 'rpm',
    }
  } elsif $facts['os']['family'] == 'RedHat' {
    $package_version = "${version}-1.el${facts['os']['release']['major']}"
    package { 'openvox-server':
      ensure => $package_version,
    }
  } else {
    package { 'openvox-server':
      ensure => $version,
    }
  }
}
