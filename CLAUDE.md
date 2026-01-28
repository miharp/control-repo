# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Puppet control repository for OpenVox (a Vox Pupuli fork of Puppet). It manages a development environment with an OpenVox Server (Puppet master) and agents running on CentOS Stream 9 and Ubuntu 24.04.

## Common Commands

### Ruby Setup (for local testing)

This project uses Ruby 3.4.8. Use [rbenv](https://github.com/rbenv/rbenv) to manage Ruby versions:

```bash
rbenv install 3.4.8    # Install the required Ruby version
rbenv local 3.4.8      # Set for this directory (creates .ruby-version)
ruby -v                # Verify: should show ruby 3.4.8
```

### Testing with Local Bundle (CI authoritative)

GitHub Actions CI uses the local bundle for linting - this is authoritative for PRs:

```bash
cd site-modules/profile
bundle install                        # Install dependencies
bundle exec rake validate lint check  # Validate syntax and lint
bundle exec rake parallel_spec        # Run all rspec-puppet tests
bundle exec rake spec SPEC=spec/classes/openvox_agent_spec.rb  # Run single spec
```

### Testing with Voxbox Container (alternative)

The [voxbox container](https://github.com/voxpupuli/container-voxbox) can be used for testing but note that it may have different lint rules than the CI bundle:

```bash
cd site-modules/profile

# Run puppet-lint
docker run --rm -v $PWD:/repo ghcr.io/voxpupuli/voxbox:8 lint

# Run all rake tasks list
docker run --rm -v $PWD:/repo ghcr.io/voxpupuli/voxbox:8

# Run spec tests
docker run --rm -v $PWD:/repo ghcr.io/voxpupuli/voxbox:8 spec

# Run a specific spec
docker run --rm -e "SPEC=spec/classes/static_catalogs_spec.rb" -v $PWD:/repo ghcr.io/voxpupuli/voxbox:8 spec

# Run syntax validation
docker run --rm -v $PWD:/repo ghcr.io/voxpupuli/voxbox:8 validate
```

### Module Management

```bash
# Install modules from Puppetfile (on the Puppet master)
/opt/puppetlabs/puppet/bin/r10k puppetfile install
```

### Vagrant Development Environment

```bash
vagrant up              # Start all VMs (puppet, agent01, agent02)
vagrant ssh puppet      # SSH to the Puppet master
vagrant ssh agent01     # SSH to CentOS agent
vagrant ssh agent02     # SSH to Ubuntu agent
vagrant provision       # Re-run provisioning
```

### Running Puppet on Agents

```bash
# From within an agent VM
sudo /opt/puppetlabs/bin/puppet agent -t
```

### Bolt Validation

```bash
./scripts/bolt-validate.sh  # Run Bolt validation plan from host
```

## Architecture

### Roles and Profiles Pattern

- **[site-modules/role/](site-modules/role/)** - Node classification (one role per node type)
- **[site-modules/profile/](site-modules/profile/)** - Technology-specific configurations composed into roles
- **[modules/](modules/)** - External modules from Puppet Forge (managed via Puppetfile)

Roles include profiles, profiles include component modules. Example: `role::puppet_master` includes `profile::base`, `profile::openvox_server`, `profile::openvoxdb`, `profile::openbolt`.

### Hiera Data

- **[hiera.yaml](hiera.yaml)** - Hierarchy configuration with eyaml and yaml backends
- **[data/](data/)** - Hiera data files
  - `nodes/%{trusted.certname}.yaml` - Per-node data
  - `common.yaml` - Default values
- **[keys/](keys/)** - eyaml PKCS7 keys (not committed, see keys/README.md for generation)

### Module Path (defined in environment.conf)

1. `site-modules/` - Local modules (role, profile, adhoc)
2. `modules/` - External Forge modules
3. `$basemodulepath` - System modules

### Bolt Project

- **[bolt-project.yaml](bolt-project.yaml)** - Project configuration
- **[inventory.yaml](inventory.yaml)** - Target inventory for agents
- **[plans/](plans/)** - Bolt plans (e.g., `control_repo::validate`)
- **[site-modules/adhoc/tasks/](site-modules/adhoc/tasks/)** - Bolt tasks

## Vagrant Environment

| VM | Hostname | IP | Description |
| --- | --- | --- | --- |
| puppet | puppet.example.com | 192.168.56.10 | OpenVox Server + PuppetDB |
| agent01 | agent01.example.com | 192.168.56.11 | CentOS Stream 9 agent |
| agent02 | agent02.example.com | 192.168.56.12 | Ubuntu 24.04 agent |

The control-repo is synced to `/etc/puppetlabs/code/environments/production` on the Puppet master.

## Testing Patterns

Tests use rspec-puppet with rspec-puppet-facts for multi-OS testing. Example spec structure:

```ruby
describe 'profile::example' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      it { is_expected.to compile }
    end
  end
end
```

Spec files go in `site-modules/profile/spec/classes/` for class tests.
