# @summary TEMP profile to exercise voxpupuli/puppet-networkmanager PR #2.
#
# Safe-scope test: installs/manages NetworkManager (already present on EL) and
# creates one throwaway connection on a slaveless *bridge* interface. A bridge
# with no enslaved ports carries no traffic, so this never disturbs agent01's
# real uplink or host-only SSH link. reapply is left false so nothing is pushed
# to the live runtime devices.
#
# Remove this profile (and its node classification) before merging the
# control-repo test branch back.
class profile::networkmanager_test {
  include networkmanager

  networkmanager_connection { 'nm-pr2-test':
    ensure         => 'present',
    type           => 'bridge',
    device         => 'br-nmtest',
    ipv4_method    => 'manual',
    ipv4_addresses => ['10.99.0.10/24'],
    ipv4_dns       => ['1.1.1.1'],
    ipv4_gateway   => '10.99.0.1',
    ipv4_routes    => [
      {
        'destination' => '10.50.0.0/24',
        'next_hop'    => '10.99.0.254',
        'metric'      => 100,
      },
    ],
    ipv6_method    => 'ignore',
    reapply        => false,
  }
}
