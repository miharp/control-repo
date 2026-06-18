# Test 3 (empty-route removal) — step B: explicit empty array should remove the
# route and then be idempotent (README claims this is normalized/idempotent).
networkmanager_connection { 'nm-pr2-routes':
  ensure         => 'present',
  type           => 'bridge',
  device         => 'br-nmrt',
  ipv4_method    => 'manual',
  ipv4_addresses => ['10.99.5.10/24'],
  ipv4_routes    => [],
  ipv6_method    => 'ignore',
  reapply        => false,
}
