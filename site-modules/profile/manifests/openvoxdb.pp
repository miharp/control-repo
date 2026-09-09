# @summary Installs and configures OpenVoxDB on the Puppet master.
#
# This profile uses the `voxpupuli/puppet-openvoxdb` module (a fork of
# puppetlabs/puppetdb with OpenVox package-name defaults) to configure
# OpenVoxDB.
#
# @see https://github.com/voxpupuli/puppet-openvoxdb
#
# @param package_version
#   Full package version string to pin (e.g. for pre-release snapshots). When
#   set, both the openvoxdb and openvoxdb-termini packages are overridden via
#   resource collectors. The module's own puppetdb_version param cannot pin
#   the termini package (its ensure is hardwired to params.pp), hence the
#   collectors. Installs from the configured repo unless the *_source params
#   are also set.
# @param package_source
#   Optional direct RPM URL for the openvoxdb package, for pre-releases not
#   yet published to a repo.
# @param termini_source
#   Optional direct RPM URL for the openvoxdb-termini package, for
#   pre-releases not yet published to a repo.
# @param java_package
#   Optional JRE package to install before openvoxdb. Direct rpm installs do
#   not resolve dependencies, so a pre-release openvoxdb needing a newer Java
#   (e.g. java-25-openjdk-headless) must have it installed first.
#
# @example
#   include profile::openvoxdb
class profile::openvoxdb (
  Optional[String] $package_version = undef,
  Optional[String] $package_source  = undef,
  Optional[String] $termini_source  = undef,
  Optional[String] $java_package    = undef,
) {
  class { 'openvoxdb': }
  class { 'openvoxdb::master::config':
    manage_report_processor => true,
    enable_reports          => true,
  }

  if $package_version {
    if $package_source {
      Package <| title == 'openvoxdb' |> {
        ensure   => $package_version,
        source   => $package_source,
        provider => 'rpm',
      }
    } else {
      Package <| title == 'openvoxdb' |> {
        ensure => $package_version,
      }
    }

    if $termini_source {
      Package <| title == 'openvoxdb-termini' |> {
        ensure   => $package_version,
        source   => $termini_source,
        provider => 'rpm',
      }
    } else {
      Package <| title == 'openvoxdb-termini' |> {
        ensure => $package_version,
      }
    }

    if $java_package {
      ensure_packages([$java_package])
      Package[$java_package] -> Package['openvoxdb']
    }
  }
}
