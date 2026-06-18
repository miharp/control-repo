# Test 5 (optional route fields) — one route with destination only, one with
# destination + next_hop but no metric. Exercises format_route_entry /
# parse_route_entry optional handling and idempotency.
networkmanager_connection { 'nm-pr2-opt':
  ensure         => 'present',
  type           => 'bridge',
  device         => 'br-nmopt',
  ipv4_method    => 'manual',
  ipv4_addresses => ['10.99.6.10/24'],
  ipv4_routes    => [
    { 'destination' => '198.51.100.0/24' },
    { 'destination' => '203.0.113.0/24', 'next_hop' => '10.99.6.254' },
  ],
  ipv6_method    => 'ignore',
  reapply        => false,
}
