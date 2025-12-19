# Puppet Control Repository - Development Environment

This control repository is for my development environment on my macOS using
Parallels and CentOS Stream 9 server and agent.

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

To access the nodes:

```bash
vagrant ssh puppet
# or
vagrant ssh agent01
```
