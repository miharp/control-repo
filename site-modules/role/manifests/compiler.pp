# @summary Role for a compiler: an OpenVox Server that compiles catalogs but issues no certificates.
#
# A compiler runs the same server package as the primary, and differs in what it
# is allowed to do rather than what it installs: its CA service is disabled and
# it enrols against the primary's CA, so the estate has exactly one authority.
# That split is set up during provisioning, because it has to happen before the
# node holds a certificate at all.
#
# The node's certificate carries `pp_role: openvox_compiler`, written into
# `csr_attributes.yaml` before enrolment. Anything that authorizes on role reads
# that extension, so it cannot be added afterwards without re-issuing the
# certificate.
#
# @example
#   include role::compiler
# It pulls code with the codavox agent. Whether OpenVox Server actually *serves*
# from that code is a separate switch — `profile::codavox::agent::wire_server` —
# because pointing a compiler at codavox before its agent has converged fails
# every catalog compile.
class role::compiler {
  include profile::base
  include profile::openvox_server
  include profile::codavox::agent
}
