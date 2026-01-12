# @summary Installs and configures OpenVoxDB (PuppetDB-compatible) on the Puppet master.
#
# This profile uses the upstream `puppetlabs/puppetdb` module to configure
# OpenVoxDB (the OpenVox-packaged PuppetDB).
#
# Package naming differences (OpenVox vs Puppet) should be handled via Hiera,
# e.g.:
#
#   puppetdb::puppetdb_package: openvoxdb
#   puppetdb::master::config::terminus_package: openvoxdb-termini
#
# @example
#   include profile::openvoxdb
class profile::openvoxdb {
  class { 'puppetdb': }
  class { 'puppetdb::master::config': }
}
