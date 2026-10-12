# @summary Role for a compiler: an OpenVox Server that compiles catalogs but issues no certificates.
#
# A compiler runs the same server package as the primary, and differs in what it
# is allowed to do rather than what it installs: its CA service is disabled and
# it enrols against the primary's CA, so the estate has exactly one authority.
# That split is set up during provisioning (ovadm::add_compiler in the Hetzner
# lab), because it has to happen before the node holds a certificate at all;
# the node data then keeps `openvox_server::ca: false` and `ca_server` so the
# profile carries the same state forward.
#
# The node's certificate carries `pp_role: openvox_compiler`, written into
# `csr_attributes.yaml` before enrolment. Anything that authorizes on role reads
# that extension, so it cannot be added afterwards without re-issuing the
# certificate.
#
# What provisioning leaves to the site and this role supplies: the PuppetDB
# terminus pointed at the primary's OpenVoxDB, so facts and reports from the
# catalogs it compiles land in the one database. Code (r10k) and the Hiera
# eyaml keys are delivered outside Puppet, as on the primary.
#
# @example
#   include role::compiler
class role::compiler {
  include profile::base
  include profile::openvox_server
  include profile::openvoxdb_terminus
  include profile::bolt_target
}
