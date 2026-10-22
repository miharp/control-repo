# @summary Points a compiler's puppetserver at the primary's OpenVoxDB
#
# The terminus half of profile::openvoxdb, for a host that compiles catalogs
# but runs no OpenVoxDB of its own: installs openvoxdb-termini, writes
# puppetdb.conf and routes.yaml for the server named in $server, turns on
# storeconfigs and the puppetdb report processor, and restarts puppetserver
# when any of that changes. The module first checks that OpenVoxDB answers on
# $server:$port with this host's certificate, which OpenVoxDB accepts for any
# certificate the CA signed.
#
# @param server
#   The OpenVoxDB host, normally the primary server.
# @param port
#   OpenVoxDB's SSL port.
# @param package_version
#   Version to pin openvoxdb-termini to. A bare version (`9.1.0`) is expanded
#   for the host's platform the way openvox_agent expands the agent's
#   (`9.1.0-1.el10`, `9.1.0-1.redhatfips9` on an EL host in FIPS mode); a
#   full package version string is used as it is. Unset, the module installs
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

  if $package_version {
    $package_ensure = openvox_agent::package_version($package_version, openvox_agent::platform(), $facts['os']['family'])
    Package <| title == 'openvoxdb-termini' |> {
      ensure => $package_ensure,
    }
  }
}
