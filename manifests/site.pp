## site.pp ##

# This file (./manifests/site.pp) is the main entry point
# used when an agent connects to a master and asks for an updated configuration.
# https://puppet.com/docs/puppet/latest/dirs_manifest.html
#
# Global objects like filebuckets and resource defaults should go in this file,
# as should the default node definition if you want to use it.

## Active Configurations ##

# Disable filebucket by default for all File resources:
# https://github.com/puppetlabs/docs-archive/blob/master/pe/2015.3/release_notes.markdown#filebucket-resource-no-longer-created-by-default
File { backup => false }

## Node Definitions ##

# The `demo` environment: a primary, compilers and agents for the codavox
# screenshare. Hosts are built by ovadm::install, which puts pp_role in each
# certificate; these roles then take them over. Classification is by
# certname, as on production.
node default {
  include role::demo_agent
}

node 'puppet.example.com' {
  include role::demo_primary
}

node /^compiler\d+\.example\.com$/ {
  include role::demo_compiler
}
