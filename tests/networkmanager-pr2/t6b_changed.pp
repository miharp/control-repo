# Test 6 (granular update churn) — step B: add a 2nd address, change the gateway,
# add a route. Expect only those properties to diff, then idempotent on re-run.
networkmanager_connection { 'nm-pr2-churn':
  ensure         => 'present',
  type           => 'bridge',
  device         => 'br-nmch',
  ipv4_method    => 'manual',
  ipv4_addresses => ['10.99.7.10/24', '10.99.7.11/24'],
  ipv4_gateway   => '10.99.7.254',
  ipv4_routes    => [
    { 'destination' => '10.60.7.0/24', 'next_hop' => '10.99.7.254', 'metric' => 200 },
  ],
  ipv6_method    => 'ignore',
  reapply        => false,
}
