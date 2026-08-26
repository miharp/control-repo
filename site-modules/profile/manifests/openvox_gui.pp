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
# Orchestration: the installer generates the console's Bolt SSH key
# (/etc/puppetlabs/bolt/id_bolt) and the GUI resolves targets from
# OpenVoxDB, so the inventory managed here only carries SSH settings
# (upstream's bolt-plugin/inventory.yaml.example without the ENC plugin
# group). Targets get the matching bolt user from profile::bolt_target.
# The GUI's Settings page can write this file too; Puppet is the source
# of truth and will put it back.
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

  # /etc/puppetlabs/bolt and the bolt group are created by the installer.
  file { '/etc/puppetlabs/bolt/inventory.yaml':
    ensure  => file,
    owner   => 'root',
    group   => 'bolt',
    mode    => '0640',
    content => @(INVENTORY),
      ---
      # Managed by Puppet (profile::openvox_gui). OpenVox GUI runs Bolt as
      # the bolt user with this inventory; targets are resolved from
      # OpenVoxDB, so only the SSH settings live here.
      config:
        ssh:
          user: bolt
          private-key: /etc/puppetlabs/bolt/id_bolt
          host-key-check: false
          tty: false
          tmpdir: /home/bolt/.bolt/tmp
      | INVENTORY
    require => Class['openvox_gui'],
  }
}
