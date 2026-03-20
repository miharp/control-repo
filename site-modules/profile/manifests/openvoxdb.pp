# @summary Installs and configures OpenVoxDB on the Puppet master.
#
# This profile uses the `voxpupuli/puppet-openvoxdb` module (a fork of
# puppetlabs/puppetdb with OpenVox package-name defaults) to configure
# OpenVoxDB.
#
# @see https://github.com/voxpupuli/puppet-openvoxdb
#
# @example
#   include profile::openvoxdb
class profile::openvoxdb {
  class { 'openvoxdb': }
  class { 'openvoxdb::master::config': }
}
