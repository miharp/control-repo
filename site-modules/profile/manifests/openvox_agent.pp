# @summary Installs the openvox-agent package
#
# Installs the openvox-agent package and points it at the OpenVox server.
#
# @param version
#   The version of the openvox-agent package to install. When $source is set
#   it is used as-is (full version-release string, no suffix appended).
# @param server
#   Value for the `server` setting in puppet.conf [main]. OpenVox 9 no longer
#   defaults to `server=puppet`: the 9.0.0-rc1 agent raises an ArgumentError
#   when run as root with the setting unset, so it is always managed here.
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
  String $server,
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
      # profile::base only refreshes the index when a source file changes, so
      # a pin moved forward on an unchanged repo was applied against a stale
      # index ("Version ... was not found"). Refresh it once when the
      # installed version differs from the pin; a no-op otherwise.
      exec { 'apt-get update for openvox-agent':
        command  => 'apt-get update',
        unless   => "dpkg-query -W -f='\${Version}' openvox-agent | grep -qx '${package_version}'",
        path     => ['/usr/bin', '/bin'],
        provider => 'shell',
        require  => Class['apt::update'],
        before   => Package['openvox-agent'],
      }
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

  ini_setting { 'puppet.conf server':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'main',
    setting => 'server',
    value   => $server,
    require => Package['openvox-agent'],
  }
}
