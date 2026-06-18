# Test 2a (validation guard) — gateway AND a default route in ipv4_routes.
# Expect a Puppet::Error: "declares both ipv4_gateway and a default route".
networkmanager_connection { 'nm-pr2-guard-a':
  ensure         => 'present',
  type           => 'bridge',
  device         => 'br-nmga',
  ipv4_method    => 'manual',
  ipv4_addresses => ['10.99.3.10/24'],
  ipv4_gateway   => '10.99.3.1',
  ipv4_routes    => [
    { 'destination' => '0.0.0.0/0', 'next_hop' => '10.99.3.1' },
  ],
  ipv6_method    => 'ignore',
}
