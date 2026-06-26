forge 'https://forge.puppet.com'

mod 'puppet/archive',        '8.1.0'
mod 'puppet/chrony',         '5.0.0'
mod 'puppet/openvoxdb',      '9.1.1'
mod 'puppet/openvoxview',    '1.4.0'
mod 'puppet/systemd',        '8.3.1'
mod 'puppet/yum',            '8.0.0'
mod 'puppetlabs/apt',        '11.3.1'
mod 'puppetlabs/concat',     '9.1.0'
mod 'puppetlabs/firewall',   '8.5.0'
mod 'puppetlabs/inifile',    '6.4.1'
mod 'puppetlabs/postgresql', '10.6.1'
mod 'puppetlabs/stdlib',     '9.7.0'
mod 'puppetlabs/vcsrepo',    '7.0.0'
mod 'saz/sudo',              '9.0.2'

# Core resource types (yumrepo, cron). These ship with the puppet-agent AIO
# package on real nodes, but are pinned explicitly so r10k and onceover (which
# runs against a gem-installed Puppet without the AIO core modules) both have
# them. Keeps the control repo self-contained and deterministic.
mod 'puppetlabs/cron_core',    '2.0.2'
mod 'puppetlabs/yumrepo_core', '3.0.1'
