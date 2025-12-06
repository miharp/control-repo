# The base profile should include component modules that will be on all nodes
class profile::base {
  notify { 'Base profile applied': }
  include chrony
  include firewall

  firewall { '100 allow puppet':
    dport  => 8140,
    proto  => 'tcp',
    jump   => 'ACCEPT',
  }

  class { 'sudo': }
  sudo::conf { 'mharp':
    content  => 'mharp ALL=(ALL) NOPASSWD: ALL',
  }
}
