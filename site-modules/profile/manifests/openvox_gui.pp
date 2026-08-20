# @summary Installs and manages the OpenVox GUI web console.
#
# Wraps the miharp/openvox_gui module (Git-sourced in the Puppetfile),
# which drives the upstream cvquesty/openvox-gui installer unattended:
# pinned release-tag checkout, pre-built React frontend, templated
# answer file, and stamp-guarded installer runs. Runs alongside
# profile::openvoxview: OpenVoxView is a read-only reports browser
# (port 5000) while the GUI is a management console (port 4567).
#
# The module's defaults fit this master: backends and TLS certs resolve
# to the node's own FQDN/certname, and its ENC, firewall, and
# package-mirror installer features stay off. The firewall port is
# opened here, consistent with the other profiles. The installer's
# sudoers rules are kept from profile::base's purge via
# sudo::purge_ignore in the node's hiera data.
#
# @param version
#   The OpenVox GUI release to install.
# @param admin_password
#   Password for the initial admin user.
# @param app_port
#   Port for the OpenVox GUI web interface.
#
# @example
#   include profile::openvox_gui
class profile::openvox_gui (
  String  $version,
  String  $admin_password,
  Integer $app_port = 4567,
) {
  class { 'openvox_gui':
    version        => $version,
    admin_password => Sensitive($admin_password),
    app_port       => $app_port,
  }

  firewall { "200 allow openvox-gui port ${app_port}":
    dport => $app_port,
    proto => 'tcp',
    jump  => 'ACCEPT',
  }
}
