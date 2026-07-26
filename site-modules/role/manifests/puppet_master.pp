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
  # Kept included on purpose while disabled: Puppet only removes what it manages,
  # so dropping the include would strand static_catalogs = true and a code_id
  # script on disk. Remove this line once every node has converged with it off.
  include profile::static_catalogs
  include profile::openvoxview
  include profile::codavox::publisher
}
