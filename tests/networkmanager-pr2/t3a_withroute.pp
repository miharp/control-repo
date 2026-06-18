# Test 3 (empty-route removal) — step A: profile with one extra static route.
networkmanager_connection { 'nm-pr2-routes':
  ensure         => 'present',
  type           => 'bridge',
  device         => 'br-nmrt',
  ipv4_method    => 'manual',
  ipv4_addresses => ['10.99.5.10/24'],
  ipv4_routes    => [
    { 'destination' => '10.50.5.0/24', 'next_hop' => '10.99.5.254', 'metric' => 100 },
  ],
  ipv6_method    => 'ignore',
  reapply        => false,
}
