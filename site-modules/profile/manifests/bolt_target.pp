# @summary Makes this node an OpenVox GUI orchestration target.
#
# Wraps openvox_gui::bolt_target (the bolt user, its upload directory, and
# its authorized keys) and adds the half the module deliberately leaves to
# the operator: passwordless sudo for that user, declared through saz/sudo
# so profile::base's sudoers purge keeps it. The GUI's "Run privileged"
# option and its file transfers depend on it.
#
# Keys come from Hiera when set. Otherwise every console's key is collected
# from PuppetDB through the openvox_gui_bolt_pubkey fact the module
# exposes, so a rebuilt console (new key) converges on the next two agent
# runs without anyone copying a key. rspec-puppet and Onceover have no
# PuppetDB: when puppetdb_query is unavailable the lookup is skipped, and
# with no keys at all nothing is declared, which is also what a target sees
# until the first console has reported its key.
#
# @param authorized_keys
#   Explicit authorized_keys lines for the bolt user. Overrides the
#   PuppetDB lookup when non-empty.
#
# @example
#   include profile::bolt_target
class profile::bolt_target (
  Array[String[1]] $authorized_keys = [],
) {
  if $authorized_keys.empty and stdlib::has_function('puppetdb_query') {
    $keys = puppetdb_query('facts[value] { name = "openvox_gui_bolt_pubkey" }').map |$fact| { $fact['value'] }.unique.sort
  } else {
    $keys = $authorized_keys
  }

  unless $keys.empty {
    class { 'openvox_gui::bolt_target':
      authorized_keys => $keys,
    }

    sudo::conf { 'bolt':
      content => 'bolt ALL=(ALL) NOPASSWD: ALL',
    }
  }
}
