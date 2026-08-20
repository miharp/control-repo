forge 'https://forge.puppet.com'

mod 'puppet/archive',        '8.1.0'
mod 'puppet/chrony',         '5.0.0'
mod 'puppet/openvoxdb',      '9.1.1'
mod 'puppet/openvoxview',    '1.4.0'
mod 'puppet/systemd',        '8.3.1'
mod 'puppet/yum',            '8.1.1'
mod 'puppetlabs/apt',        '11.3.2'
mod 'puppetlabs/concat',     '9.1.0'
mod 'puppetlabs/firewall',   '8.5.0'
mod 'puppetlabs/inifile',    '6.4.1'
mod 'puppetlabs/postgresql', '10.6.3'
mod 'puppetlabs/stdlib',     '9.7.0'
mod 'puppetlabs/vcsrepo',    '7.0.0'
# yumrepo left Puppet core, so it has to be declared to exist in a compile-only
# environment. Real nodes get it bundled with openvox-agent, which is why
# profile::base worked on them while onceover failed on every RedHat role with
# "Unknown resource type: 'yumrepo'". site-modules/profile/.fixtures.yml already
# declared it for the module's own specs; the control repo never shipped it.
mod 'puppetlabs/yumrepo_core', '3.0.1'
mod 'saz/sudo',              '9.0.2'

# Not yet published to the Forge; consumed straight from Git at a release
# tag. Depends on vcsrepo and stdlib, both declared above (r10k does not
# resolve dependencies of Git-sourced modules).
mod 'openvox_gui',
  git: 'https://github.com/miharp/puppet-openvox_gui.git',
  ref: 'v0.1.1'
