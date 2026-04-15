# @summary Installs and manages OpenVoxView on the Puppet master.
#
# OpenVoxView provides a web UI for browsing OpenVox/Puppet reports and
# catalogs. It connects to the local PuppetDB instance.
#
# @param version
#   The version of the OpenVoxView application to install.
#
# @example
#   include profile::openvoxview
class profile::openvoxview (
  String $version,
) {
  class { 'openvoxview':
    version => $version,
  }
}
