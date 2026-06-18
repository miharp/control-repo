# Test 6 (granular update churn) — step A: initial single-address profile.
networkmanager_connection { 'nm-pr2-churn':
  ensure         => 'present',
  type           => 'bridge',
  device         => 'br-nmch',
  ipv4_method    => 'manual',
  ipv4_addresses => ['10.99.7.10/24'],
  ipv4_gateway   => '10.99.7.1',
  ipv6_method    => 'ignore',
  reapply        => false,
}
