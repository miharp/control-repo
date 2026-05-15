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
#   resource collectors. Requires package_source and termini_source.
# @param package_source
#   Direct RPM URL for the openvoxdb package. Intended for pre-release testing.
# @param termini_source
#   Direct RPM URL for the openvoxdb-termini package. Intended for pre-release testing.
#
# @example
#   include profile::openvoxdb
class profile::openvoxdb (
  Optional[String] $package_version = undef,
  Optional[String] $package_source  = undef,
  Optional[String] $termini_source  = undef,
) {
  class { 'openvoxdb': }
  class { 'openvoxdb::master::config':
    manage_report_processor => true,
    enable_reports          => true,
  }

  if $package_source {
    Package <| title == 'openvoxdb' |> {
      ensure   => $package_version,
      source   => $package_source,
      provider => 'rpm',
    }
  }

  if $termini_source {
    Package <| title == 'openvoxdb-termini' |> {
      ensure   => $package_version,
      source   => $termini_source,
      provider => 'rpm',
    }
  }
}
