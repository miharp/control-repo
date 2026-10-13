# @summary A demo compiler: OpenVox Server with its CA off, serving code codavox delivers.
#
# ovadm::install enrolled the host against the primary's CA with
# pp_role: openvox_compiler in its certificate, which is what the publisher's
# allowlist checks. openvox_server keeps the CA service off (node data);
# codavox::agent pulls each deploy and codavox::server points OpenVox Server at
# what it deployed.
class role::demo_compiler {
  include openvox_server
  include codavox::agent
  include codavox::server
}
