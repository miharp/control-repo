# @summary Role for the Puppet master (OpenVox Server) node.
#
# This role includes profiles needed to run a Puppet master in this environment.
#
# @example
#   include role::puppet_master
class role::puppet_master {
  include profile::base
  include profile::openvox_server
  include profile::openvoxdb
  include profile::openbolt
}
