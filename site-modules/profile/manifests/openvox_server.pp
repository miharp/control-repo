# @summary Manages the OpenVox Server through miharp/openvox_server
#
# The module owns the server package, the CA, webserver.conf, the settings
# in puppet.conf and ca.conf, and the puppetserver service. This profile
# keeps what the control-repo owns around it: the agent package and the
# repository stay with profile::base and profile::openvox_agent, so the
# module is told not to manage them, and the server package is ordered
# before the agent for a move across a major version.
#
# @param version
#   The openvox-server version to install, expanded for the platform by the
#   module (`8.17.0` becomes `8.17.0-1.el10`).
# @param release
#   The OpenVox major the host is on, the collection the server comes from.
#   Unset, profile::base's release pin is looked up.
# @param java_package
#   Optional JRE package to install before the server, for a pre-release
#   server that needs a newer Java than the package requires.
# @param r10k_ensure
#   Ensure value for the r10k gem in the agent's bundled Ruby (puppet_gem).
#
# @example
#   include profile::openvox_server
class profile::openvox_server (
  String[1]           $version,
  Optional[Integer[8]] $release     = undef,
  Optional[String[1]] $java_package = undef,
  String[1]           $r10k_ensure  = 'installed',
) {
  $collection_release = $release.lest || { lookup('profile::base::release') }

  class { 'openvox_server':
    collection      => "openvox${collection_release}",
    package_version => $version,
    manage_agent    => false,
    java_package    => $java_package,
  }

  # Server and agent pin each other's major version (openvox-server 8.x
  # requires openvox-agent < 9.0.0~, 9.x requires >= 9.0.0~), so neither can
  # cross a major on its own. Let the package manager move the server first,
  # which upgrades the agent in the same transaction, then the agent
  # resource applies its own pin on top. The module does this itself when it
  # manages the agent; here profile::openvox_agent does.
  Package['openvox-server'] -> Package <| title == 'openvox-agent' |>

  # r10k lives in the agent's bundled Ruby, and each OpenVox major ships a new
  # Ruby (8.x: 3.2, 9.x: 4.0) with its own gem directory, so crossing a major
  # leaves the r10k binstub pointing at a gem the new Ruby cannot find. Order
  # it after the agent: puppet_gem only lists installed gems when it reaches
  # its first resource, so on the run that moves the agent it checks, and
  # installs into, the new Ruby.
  package { 'r10k':
    ensure   => $r10k_ensure,
    provider => 'puppet_gem',
  }
  Package <| title == 'openvox-agent' |> -> Package['r10k']
}
