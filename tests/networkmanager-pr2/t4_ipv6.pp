# Test 4 (IPv6 manual) — exercise the ipv6 path: addresses, dns, gateway and an
# ipv6_routes entry (different Struct: String[1] rather than the ipv4 Pattern).
# ipv4 is disabled so only the v6 stack is managed.
networkmanager_connection { 'nm-pr2-v6':
  ensure         => 'present',
  type           => 'bridge',
  device         => 'br-nmv6',
  ipv4_method    => 'disabled',
  ipv6_method    => 'manual',
  ipv6_addresses => ['2001:db8::10/64'],
  ipv6_dns       => ['2001:4860:4860::8888'],
  ipv6_gateway   => '2001:db8::1',
  ipv6_routes    => [
    { 'destination' => '2001:db8:1::/64', 'next_hop' => '2001:db8::2', 'metric' => 50 },
  ],
  reapply        => false,
}
