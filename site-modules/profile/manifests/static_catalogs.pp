# @summary Enables static catalogs on the Puppet Server.
#
# This profile configures Puppet Server to use static catalogs, which
# improve agent performance by inlining file metadata and content into
# the compiled catalog.
#
# Static catalogs require:
# - The `code_id_command` setting pointing to a script that returns a unique code version
# - The `code_content_command` setting pointing to a script that retrieves file content
# - The `static_catalogs` setting enabled in puppet.conf
# - The versioned-code settings in puppetserver's HOCON configuration
#
# @param enabled
#   Whether to enable static catalogs. Default: true.
#
# @param scripts_dir
#   Directory where the static catalog scripts are deployed.
#   Default: /opt/puppetlabs/server/data/puppetserver/scripts
#
# @param puppet_confdir
#   Path to the Puppet configuration directory.
#   Default: /etc/puppetlabs/puppet
#
# @param puppetserver_confdir
#   Path to the Puppet Server configuration directory.
#   Default: /etc/puppetlabs/puppetserver/conf.d
#
# @example Basic usage
#   include profile::static_catalogs
#
# @example Disable static catalogs
#   class { 'profile::static_catalogs':
#     enabled => false,
#   }
#
class profile::static_catalogs (
  Boolean $enabled                            = true,
  Stdlib::Absolutepath $scripts_dir           = '/opt/puppetlabs/server/data/puppetserver/scripts',
  Stdlib::Absolutepath $puppet_confdir        = '/etc/puppetlabs/puppet',
  Stdlib::Absolutepath $puppetserver_confdir  = '/etc/puppetlabs/puppetserver/conf.d',
) {
  # Ensure scripts directory exists
  file { $scripts_dir:
    ensure => directory,
    owner  => 'puppet',
    group  => 'puppet',
    mode   => '0755',
  }

  # Deploy code_id script
  file { "${scripts_dir}/code_id.sh":
    ensure  => file,
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0755',
    source  => 'puppet:///modules/profile/static_catalogs/code_id.sh',
    require => File[$scripts_dir],
  }

  # Deploy code_content script
  file { "${scripts_dir}/code_content.sh":
    ensure  => file,
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0755',
    source  => 'puppet:///modules/profile/static_catalogs/code_content.sh',
    require => File[$scripts_dir],
  }

  # static_catalogs is a real Puppet setting (defaults to true); set it in
  # puppet.conf [server] to make the intent explicit.
  ini_setting { 'static_catalogs':
    ensure  => $enabled ? { true => 'present', false => 'absent' },
    path    => "${puppet_confdir}/puppet.conf",
    section => 'server',
    setting => 'static_catalogs',
    value   => $enabled,
    notify  => Service['puppetserver'],
  }

  # code_id_command and code_content_command are NOT Puppet settings; Puppet
  # Server reads them from versioned-code.conf (below), not puppet.conf. Earlier
  # revisions wrote them here, where they did nothing. Purge them so a node that
  # ran the old profile does not keep two inert, misleading lines.
  ini_setting { 'purge inert code_id_command':
    ensure  => 'absent',
    path    => "${puppet_confdir}/puppet.conf",
    section => 'server',
    setting => 'code_id_command',
  }

  ini_setting { 'purge inert code_content_command':
    ensure  => 'absent',
    path    => "${puppet_confdir}/puppet.conf",
    section => 'server',
    setting => 'code_content_command',
  }

  # This is the setting that actually plugs the commands into Puppet Server.
  $versioned_code_ensure = $enabled ? {
    true  => 'file',
    false => 'absent',
  }

  file { "${puppetserver_confdir}/versioned-code.conf":
    ensure  => $versioned_code_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('profile/static_catalogs/versioned-code.conf.epp', {
      'code_id_command'      => "${scripts_dir}/code_id.sh",
      'code_content_command' => "${scripts_dir}/code_content.sh",
    }),
    notify  => Service['puppetserver'],
  }

  # Ensure puppetserver service is defined
  # Using ensure_resource to avoid duplicate declarations
  ensure_resource('service', 'puppetserver', {
    ensure => 'running',
    enable => true,
  })
}
