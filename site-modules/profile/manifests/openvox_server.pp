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
# @param java_package
#   Optional JRE package to install before the server. Direct rpm installs do
#   not resolve dependencies, so a pre-release server needing a newer Java
#   (e.g. java-25-openjdk-headless) must have it installed first.
#
# @example
#   include profile::openvox_server
class profile::openvox_server (
  String $version,
  Optional[String] $source = undef,
  Optional[String] $java_package = undef,
) {
  if $source {
    package { 'openvox-server':
      ensure   => $version,
      source   => $source,
      provider => 'rpm',
    }

    if $java_package {
      ensure_packages([$java_package])
      Package[$java_package] -> Package['openvox-server']
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

  # A 9.x server requires a 9.x agent. If the agent package is managed in this
  # catalog (it always is via profile::base), upgrade it first so the server's
  # dependency is satisfied by the pinned agent rather than whatever the repo
  # happens to resolve. Direct rpm installs resolve no dependencies at all, so
  # there the ordering is mandatory. No-op edge when the agent is unmanaged.
  Package <| title == 'openvox-agent' |> -> Package['openvox-server']
}
