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

    # rpm resolves no dependencies, so the (managed) agent must already
    # satisfy the server's agent requirement before the server is installed.
    # No-op edge when the agent package is not in the catalog.
    Package <| title == 'openvox-agent' |> -> Package['openvox-server']
  } elsif $facts['os']['family'] == 'RedHat' {
    $package_version = "${version}-1.el${facts['os']['release']['major']}"
    package { 'openvox-server':
      ensure => $package_version,
    }

    # Server and agent pin each other's major version (openvox-server 8.x
    # requires openvox-agent < 9.0.0~, 9.x requires >= 9.0.0~), so neither can
    # cross a major on its own: a lone agent upgrade fails on the installed
    # server's dependency. Let dnf move the server first, which upgrades the
    # agent in the same transaction, then the agent resource applies its own
    # pin (e.g. a newer rpm from the artifact bucket) on top.
    Package['openvox-server'] -> Package <| title == 'openvox-agent' |>
  } else {
    package { 'openvox-server':
      ensure => $version,
    }
  }
}
