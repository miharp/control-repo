# Puppet Control Repository - Development Environment

This control repository is for my development environment on my macOS using
Parallels with a CentOS Stream 9 Puppet server, plus CentOS and Ubuntu agents.

## Vagrant Environment

This repository includes a `Vagrantfile` to spin up a local development
environment with a Puppet Master and an Agent node.

### Prerequisites

- Vagrant
- Parallels Desktop (provider configured in Vagrantfile)

### Usage

To bring up the environment:

```bash
vagrant up
```

This will provision:

- **puppet.example.com** (192.168.56.10): Puppet Master (OpenVox Server)
- **agent01.example.com** (192.168.56.11): Puppet Agent (OpenVox Agent)
- **agent02.example.com** (192.168.56.12): Puppet Agent (OpenVox Agent, Ubuntu LTS)

Boxes used:

- `bento/centos-stream-9` (puppet, agent01)
- `bento/ubuntu-24.04` (agent02, current Ubuntu LTS)

To access the nodes:

```bash
vagrant ssh puppet
# or
vagrant ssh agent01
# or
vagrant ssh agent02
```

### Bolt validation

This environment provisions OpenBolt (Bolt) on the Puppet master and includes a
simple plan to validate Bolt can SSH to both agents.

Run from your host:

```bash
./scripts/bolt-validate.sh
```

If you rebuilt the environment and the Bolt SSH key hasnt propagated to agents
yet, re-run:

```bash
vagrant provision agent01 agent02
```
