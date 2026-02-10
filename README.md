# OpenVox Control Repository

[![CI](https://github.com/miharp/control-repo/actions/workflows/puppet.yml/badge.svg?branch=production)](https://github.com/miharp/control-repo/actions/workflows/puppet.yml)
[![Apache-2 License](https://img.shields.io/github/license/miharp/control-repo.svg)](LICENSE)

A Puppet control repository for managing an OpenVox development environment with a Puppet master and agents on CentOS Stream 9 and Ubuntu 24.04.

## Quick Start

```bash
# Start the Vagrant environment
vagrant up

# SSH to nodes
vagrant ssh puppet      # Puppet master
vagrant ssh agent01     # CentOS agent
vagrant ssh agent02     # Ubuntu agent

# Run Puppet on an agent
vagrant ssh agent01 -c "sudo /opt/puppetlabs/bin/puppet agent -t"
```

## Environment

| VM | Hostname | IP | OS |
| --- | --- | --- | --- |
| puppet | puppet.example.com | 192.168.56.10 | CentOS Stream 9 |
| agent01 | agent01.example.com | 192.168.56.11 | CentOS Stream 9 |
| agent02 | agent02.example.com | 192.168.56.12 | Ubuntu 24.04 |

## Prerequisites

- [Vagrant](https://www.vagrantup.com/) with Parallels provider
- [rbenv](https://github.com/rbenv/rbenv) (for local testing)

## Documentation

See the [Wiki](https://github.com/miharp/control-repo/wiki) for detailed documentation:

- [Getting Started](https://github.com/miharp/control-repo/wiki/Getting-Started)
- [Architecture](https://github.com/miharp/control-repo/wiki/Architecture)
- [Testing](https://github.com/miharp/control-repo/wiki/Testing)
- [Vagrant Environment](https://github.com/miharp/control-repo/wiki/Vagrant-Environment)

## Structure

```text
site-modules/
  role/       # Node classification (one role per node)
  profile/    # Technology-specific configurations
  adhoc/      # Bolt tasks
modules/      # External Forge modules (via Puppetfile)
data/         # Hiera data
plans/        # Bolt plans
```

## Testing

```bash
cd site-modules/profile
bundle install
bundle exec rake validate lint check
bundle exec rake parallel_spec
```

## Resources

- [OpenVox Project](https://github.com/voxpupuli)
- [Puppet Documentation](https://www.puppet.com/docs/puppet/latest/)
- [Voxbox Container](https://github.com/voxpupuli/container-voxbox)
