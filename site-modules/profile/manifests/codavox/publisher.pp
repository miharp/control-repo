# @summary Runs the codavox publisher, which serves versioned code to compilers.
#
# OpenVox Server ships without Puppet Enterprise's Code Manager and file sync, so
# nothing gets resolved code onto a compiler or lets a compiler say which version
# it is serving. [codavox](https://github.com/miharp/codavox) fills that gap.
#
# This profile belongs on the node where r10k runs, because the publisher reads
# r10k's output directory locally. It seals each environment into a
# content-addressed `code_id` and serves the result to compilers over mutual TLS,
# reusing the Puppet CA material already on the node — there is no second PKI to
# provision.
#
# Settings come from Hiera under `codavox::*` rather than from parameters here, so
# a node that ends up running both the publisher and an agent cannot declare the
# `codavox` class twice with different data. See `data/common.yaml`.
#
# @param port
#   The port the publisher listens on, used for the firewall rule. Must agree
#   with `codavox::publish_listen`, which is what codavox actually reads.
#
# @example
#   include profile::codavox::publisher
class profile::codavox::publisher (
  Stdlib::Port $port = 8150,
) {
  include codavox
  include codavox::publish

  # Compilers dial in; nothing connects out to them. This is the only inbound
  # rule codavox needs anywhere in the estate.
  firewall { '100 allow codavox publisher':
    dport => $port,
    proto => 'tcp',
    jump  => 'ACCEPT',
  }
}
