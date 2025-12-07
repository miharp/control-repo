# @summary Installs the openvox-agent package
#
# Installs the openvox-agent package
#
# @param version
#   The version of the openvox-agent package to install.
#
# @example
#   include profile::openvox_agent
class profile::openvox_agent (
  String $version,
) {
  package { 'openvox-agent':
    ensure => $version,
  }
}
