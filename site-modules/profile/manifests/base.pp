# The base profile should include component modules that will be on all nodes
class profile::base (
  Integer $release,
) {
  include chrony
  include firewall
  include profile::openvox_agent

  firewall { '100 allow puppet':
    dport => 8140,
    proto => 'tcp',
    jump  => 'ACCEPT',
  }

  class { 'sudo': }
  sudo::conf { 'mharp':
    content => 'mharp ALL=(ALL) NOPASSWD: ALL',
  }

  $os_name = $facts['os']['name'] ? {
    'Fedora' => 'fedora',
    default  => 'el',
  }
  $url = "https://yum.voxpupuli.org/openvox${release}-release-${os_name}-${facts['os']['release']['major']}.noarch.rpm"

  package { "openvox${release}-release":
    ensure   => present,
    provider => 'rpm',
    source   => $url,
  }
}
