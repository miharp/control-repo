# @summary Enables static catalogs on the Puppet Server.
#
# This profile configures Puppet Server to use static catalogs, which
# improve agent performance by inlining file metadata and content into
# the compiled catalog.
#
# Static catalogs require:
# - The `code_id_command` setting pointing to a script that returns a unique code version
# - The `code_content_command` setting pointing to a script that retrieves file content
# - The `static_catalogs` setting enabled
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
# @example Basic usage
#   include profile::static_catalogs
#
# @example Disable static catalogs
#   class { 'profile::static_catalogs':
#     enabled => false,
#   }
#
class profile::static_catalogs (
  Boolean $enabled                       = true,
  Stdlib::Absolutepath $scripts_dir      = '/opt/puppetlabs/server/data/puppetserver/scripts',
  Stdlib::Absolutepath $puppet_confdir   = '/etc/puppetlabs/puppet',
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

  # Configure puppet.conf settings using ini_setting
  # The [server] section is used for Puppet Server settings
  $ensure_value = $enabled ? {
    true  => 'present',
    false => 'absent',
  }

  Ini_setting {
    ensure  => $ensure_value,
    path    => "${puppet_confdir}/puppet.conf",
    section => 'server',
    notify  => Service['puppetserver'],
  }

  ini_setting { 'static_catalogs':
    setting => 'static_catalogs',
    value   => $enabled,
  }

  ini_setting { 'code_id_command':
    setting => 'code_id_command',
    value   => "${scripts_dir}/code_id.sh",
  }

  ini_setting { 'code_content_command':
    setting => 'code_content_command',
    value   => "${scripts_dir}/code_content.sh",
  }

  # Ensure puppetserver service is defined
  # Using ensure_resource to avoid duplicate declarations
  ensure_resource('service', 'puppetserver', {
      ensure => 'running',
      enable => true,
  })
}
