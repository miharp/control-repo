# @summary Points a compiler's puppetserver at the primary's OpenVoxDB
#
# The terminus half of profile::openvoxdb, for a host that compiles catalogs
# but runs no OpenVoxDB of its own: installs openvoxdb-termini, writes
# puppetdb.conf and routes.yaml for the server named in $server, turns on
# storeconfigs and the puppetdb report processor, and restarts puppetserver
# when any of that or the package changes. The module first checks that
# OpenVoxDB answers on $server:$port with this host's certificate, which
# OpenVoxDB accepts for any certificate the CA signed.
#
# @param server
#   The OpenVoxDB host, normally the primary server.
# @param port
#   OpenVoxDB's SSL port.
# @param package_version
#   Full package version string to pin openvoxdb-termini to, as
#   profile::openvoxdb pins it on the primary; unset, the module installs
#   whatever the repository offers.
#
# @example
#   include profile::openvoxdb_terminus
class profile::openvoxdb_terminus (
  Stdlib::Fqdn     $server          = 'puppet.example.com',
  Stdlib::Port     $port            = 8081,
  Optional[String] $package_version = undef,
) {
  class { 'openvoxdb::master::config':
    puppetdb_server         => $server,
    puppetdb_port           => $port,
    manage_report_processor => true,
    enable_reports          => true,
  }

  # The module restarts puppetserver when the terminus configuration changes,
  # but not when the terminus package does. puppetserver keeps the old code
  # loaded until it restarts, and a termini release can be a fix on its own
  # (GHSA-859m-7qpm-85p7 in 8.18.1 and 9.2.1), so restart it on an upgrade.
  Package['openvoxdb-termini'] ~> Service['puppetserver']

  if $package_version {
    Package <| title == 'openvoxdb-termini' |> {
      ensure => $package_version,
    }
  }
}
