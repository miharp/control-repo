# @summary Configures OpenVox Server's own static-catalog commands. Superseded.
#
# Static catalogs inline file metadata into the catalog, which requires the server
# to answer "which version of the code is this?" for every compile — the
# `code_id`. This profile answered it with hand-written scripts, and
# [codavox](https://github.com/miharp/codavox) now answers it properly. Prefer
# `profile::codavox::agent` with `wire_server => true`.
#
# # Why this is off on the primary
#
# The scripts cannot produce a correct `code_id` here. `code_id.sh` returns
# `git rev-parse HEAD`, but the primary serves `production` from the Vagrant
# synced *working tree* — so an uncommitted edit changes the content the server
# hands out while leaving the `code_id` identical. Two catalogs then claim the
# same version over different files, which is the exact failure static catalogs
# exist to prevent.
#
# It is worse when there is no git checkout at all: the script falls through to
# `date +%s`, inventing a `code_id` that describes nothing, and writes a warning
# to stderr while exiting 0 — which OpenVox Server logs at ERROR on every single
# compile.
#
# Setting `enabled => false` removes the settings *and* the scripts, so nothing is
# left behind still claiming to version the code.
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
  Boolean $enabled                            = false,
  Stdlib::Absolutepath $scripts_dir           = '/opt/puppetlabs/server/data/puppetserver/scripts',
  Stdlib::Absolutepath $puppet_confdir        = '/etc/puppetlabs/puppet',
  Stdlib::Absolutepath $puppetserver_confdir  = '/etc/puppetlabs/puppetserver/conf.d',
) {
  $script_ensure = $enabled ? {
    true  => 'file',
    false => 'absent',
  }
  # An absent file takes no source, so these go undef when disabled.
  $code_id_source = $enabled ? {
    true  => 'puppet:///modules/profile/static_catalogs/code_id.sh',
    false => undef,
  }
  $code_content_source = $enabled ? {
    true  => 'puppet:///modules/profile/static_catalogs/code_content.sh',
    false => undef,
  }

  # The directory is left alone either way: puppetserver owns it and may hold
  # other scripts, so removing it would reach beyond this profile.
  file { $scripts_dir:
    ensure => directory,
    owner  => 'puppet',
    group  => 'puppet',
    mode   => '0755',
  }

  # Deploy code_id script
  file { "${scripts_dir}/code_id.sh":
    ensure  => $script_ensure,
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0755',
    source  => $code_id_source,
    require => File[$scripts_dir],
  }

  # Deploy code_content script
  file { "${scripts_dir}/code_content.sh":
    ensure  => $script_ensure,
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0755',
    source  => $code_content_source,
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

  # Configure Puppet Server's versioned-code service (HOCON format)
  # This is required for Puppet Server to actually use the code_id and code_content commands
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
