# @summary Pulls versioned code onto this compiler, and optionally serves from it.
#
# The agent polls the publisher, verifies each artifact against its `code_id`, and
# swaps the environment symlink atomically. Compilers poll rather than being pushed
# to, so a compiler that was down across a deploy catches up on its own with no
# event replayed to it.
#
# The publisher URL and everything else come from Hiera under `codavox::*` — see
# `data/common.yaml`. codavox itself fails with a clear message if
# `codavox::agent_publisher` is unset, so there is nothing to re-validate here.
#
# @param wire_server
#   Whether to point OpenVox Server at codavox — `environmentpath`,
#   `static_catalogs`, and the two versioned-code commands.
#
#   **Deliberately false by default.** codavox has no fallback: once OpenVox
#   Server is pointed at it, catalog compilation depends on the agent having
#   deployed code there. Wiring a compiler before its agent has converged fails
#   every catalog compile — loudly, which is correct, but it fails. So the safe
#   order is to install and converge first, confirm with `codavox code-id
#   production` on this node and `codavox compilers` on the publisher, and only
#   then set this true.
#
#   Leaving it false is not a half-configured state: the agent keeps this node's
#   codavox tree current either way, so flipping it later is a restart rather than
#   a wait.
#
# @example Stage 1 — converge, without touching catalog compilation
#   include profile::codavox::agent
#
# @example Stage 2 — serve from it, once code-id answers
#   profile::codavox::agent::wire_server: true
class profile::codavox::agent (
  Boolean $wire_server = false,
) {
  include codavox
  include codavox::agent

  if $wire_server {
    # Left at the default service_manage => true on purpose: nothing else on a
    # compiler declares the puppetserver service — profile::openvox_server manages
    # only the package — so codavox has to declare it for the wiring change to
    # restart anything.
    include codavox::server
  }
}
