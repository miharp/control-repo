# Test 2b (validation guard) — a route for the connected network already implied
# by ipv4_addresses (10.99.4.0/24). Expect a Puppet::Error: "declares connected
# network ... it is created automatically from ipv4_addresses".
networkmanager_connection { 'nm-pr2-guard-b':
  ensure         => 'present',
  type           => 'bridge',
  device         => 'br-nmgb',
  ipv4_method    => 'manual',
  ipv4_addresses => ['10.99.4.10/24'],
  ipv4_routes    => [
    { 'destination' => '10.99.4.0/24', 'next_hop' => '10.99.4.254' },
  ],
  ipv6_method    => 'ignore',
}
