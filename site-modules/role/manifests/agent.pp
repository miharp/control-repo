# @summary A managed node that is not the Puppet master.
#
# Base configuration plus OpenVox GUI orchestration access (the bolt user
# the console logs in as).
class role::agent {
  include profile::base
  include profile::bolt_target
}
