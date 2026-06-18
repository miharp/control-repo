# Test 1 (delete path) — step A: create the profile so we have something to remove.
networkmanager_connection { 'nm-pr2-del':
  ensure         => 'present',
  type           => 'bridge',
  device         => 'br-nmdel',
  ipv4_method    => 'manual',
  ipv4_addresses => ['10.99.2.10/24'],
  ipv6_method    => 'ignore',
  reapply        => false,
}
