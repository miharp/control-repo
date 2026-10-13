# @summary The demo primary: OpenVox Server with the CA, and the codavox publisher.
#
# ovadm::install built the host. openvox_server takes the server over from a
# Puppet run and, with the same inputs, changes nothing on its first run.
# codavox::primary runs the publisher, this node's own codavox agent, and wires
# OpenVox Server to codavox once the environment has converged, so the catalogs
# this node compiles for itself are versioned like everyone else's.
class role::demo_primary {
  include openvox_server
  include codavox::primary
}
