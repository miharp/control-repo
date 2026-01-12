# @summary Install OpenBolt (Bolt) on the Puppet master.
#
# OpenVox packages OpenBolt as the `openbolt` package, but it provides the
# standard `bolt` CLI under /opt/puppetlabs/bin/bolt.
#
# @example
#   include profile::openbolt
class profile::openbolt {
  package { 'openbolt':
    ensure => installed,
  }
}
