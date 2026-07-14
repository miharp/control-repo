# @summary Installs the openvox-agent package
#
# Installs the openvox-agent package
#
# @param version
#   The version of the openvox-agent package to install. When $source is set
#   it is used as-is (full version-release string, no suffix appended).
# @param source
#   Optional direct URL to a package. When set, installs from the URL instead
#   of a repo. Intended for pre-release/snapshot testing. On Ubuntu the .deb
#   is downloaded first and pinned via ensure=latest, because dpkg cannot
#   fetch URLs and is not versionable.
#
# @example
#   include profile::openvox_agent
class profile::openvox_agent (
  String $version,
  Optional[String] $source = undef,
) {
  if $source {
    if $facts['os']['family'] == 'RedHat' {
      package { 'openvox-agent':
        ensure   => $version,
        source   => $source,
        provider => 'rpm',
      }
    } else {
      $deb_path = "/var/cache/openvox-agent_${version}.deb"
      file { $deb_path:
        ensure => file,
        source => $source,
      }
      # 'latest' resolves to the version inside the downloaded .deb, so this
      # is still a deterministic pin (dpkg is not versionable).
      package { 'openvox-agent':
        ensure   => 'latest', # lint:ignore:package_ensure
        source   => $deb_path,
        provider => 'dpkg',
        require  => File[$deb_path],
      }
    }
  } else {
    if $facts['os']['family'] == 'RedHat' {
      $package_version = "${version}-1.el${facts['os']['release']['major']}"
      $package_require = undef
    } elsif $facts['os']['name'] == 'Ubuntu' {
      $package_version = "${version}-1+ubuntu${facts['os']['release']['full']}"
      include apt
      $package_require = Class['apt::update']
    } else {
      $package_version = $version
      $package_require = undef
    }

    package { 'openvox-agent':
      ensure  => $package_version,
      require => $package_require,
    }
  }
}
