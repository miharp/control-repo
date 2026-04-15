# @summary Installs and manages OpenVoxView on the Puppet master.
#
# OpenVoxView provides a web UI for browsing OpenVox/Puppet reports and
# catalogs. It connects to the local PuppetDB instance.
#
# @param version
#   The version of the OpenVoxView application to install.
# @param listen_address
#   Address to bind the OpenVoxView web server to.
# @param listen_port
#   Port for the OpenVoxView web server.
#
# @example
#   include profile::openvoxview
class profile::openvoxview (
  String  $version,
  String  $listen_address = '0.0.0.0',
  Integer $listen_port    = 5000,
) {
  class { 'openvoxview':
    version        => $version,
    listen_address => $listen_address,
    listen_port    => $listen_port,
  }

  firewall { '100 allow openvoxview':
    dport => $listen_port,
    proto => 'tcp',
    jump  => 'ACCEPT',
  }
}
