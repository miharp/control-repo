forge 'https://forge.puppet.com'

# Modules from the Puppet Forge
# Versions should be updated to be the latest at the time you start
mod 'puppetlabs/inifile', '6.2.0'
mod 'puppetlabs/stdlib',  '9.7.0'
mod 'puppetlabs/concat',  '9.1.0'
#mod 'puppetlabs/ntp',     '11.1.0'
mod 'puppet/chrony',      '5.0.0'
mod 'puppetlabs/vcsrepo', '7.0.0'
mod 'puppetlabs/firewall','8.2.0'
mod 'puppetlabs/apt',     '11.2.0'
mod 'puppet/yum',         '7.3.0'
mod 'saz/sudo',           '9.0.2'

# OpenVoxDB management (Vox Pupuli fork of puppetlabs/puppetdb)
# Not yet on Puppet Forge — pulled from Git. Pinned to main for OpenVox
# package-name defaults (not available in any tagged release yet).
# https://github.com/voxpupuli/puppet-openvoxdb
mod 'openvoxdb',
  git: 'https://github.com/voxpupuli/puppet-openvoxdb.git',
  commit: 'b32a25f'
mod 'puppetlabs/postgresql', '10.0.0'
mod 'puppet/archive', '8.1.0'
mod 'puppet/systemd', '8.3.1'

# OpenVoxView (not yet on Forge)
# https://github.com/voxpupuli/puppet-openvoxview
mod 'openvoxview',
  git: 'https://github.com/voxpupuli/puppet-openvoxview.git',
  tag: 'v1.3.0'

# --- TEMP: testing voxpupuli/puppet-networkmanager PR #2 (branch: improvements) ---
# Remove before merging this control-repo branch back. r10k does not resolve
# module dependencies, so extlib (a networkmanager dependency) is listed too.
# Pin to the PR head SHA instead of the branch for a frozen test.
mod 'networkmanager',
  git: 'https://github.com/voxpupuli/puppet-networkmanager.git',
  branch: 'improvements'
# pin alternative: commit: 'bdeb997d5274a8038f20c45791ae81c4d71fa84b'
mod 'puppet/extlib', '7.5.1'

# Modules from Git
# Examples: https://github.com/puppetlabs/r10k/blob/master/doc/puppetfile.mkd#examples
#mod 'apache',
#  git:    'https://github.com/puppetlabs/puppetlabs-apache',
#  commit: '1b6f89afdde0df7f9433a163d5c4b5328eac5779'

#mod 'apache',
#  git:    'https://github.com/puppetlabs/puppetlabs-apache',
#  branch: 'docs_experiment'
