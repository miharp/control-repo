# OpenVox Control Repository

[![CI](https://github.com/miharp/control-repo/actions/workflows/puppet.yml/badge.svg?branch=production)](https://github.com/miharp/control-repo/actions/workflows/puppet.yml)
[![Apache-2 License](https://img.shields.io/github/license/miharp/control-repo.svg)](LICENSE)

A Puppet control repository for managing an OpenVox development environment with a Puppet master on CentOS Stream 10 and agents on CentOS Stream 9 and Ubuntu 24.04.

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
| puppet | puppet.example.com | 192.168.56.10 | CentOS Stream 10 |
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

Three layers, each catching something the others can't. All three run in
[CI](.github/workflows/puppet.yml) on every pull request. The tools themselves
are documented upstream in the
[OpenVox ecosystem docs](https://docs.openvoxproject.org/ecosystem/latest/).

| Layer | Tool | Scope | Run from |
| --- | --- | --- | --- |
| Unit | [rspec-puppet](https://github.com/puppetlabs/rspec-puppet) (via `voxpupuli-test`) | Each profile class in isolation, across OS fact sets | `site-modules/profile/` |
| Compilation | [Onceover](https://github.com/voxpupuli/onceover) | Every *role*, against real node facts and this repo's Hiera data | repo root |
| Acceptance | [Beaker](https://github.com/voxpupuli/beaker) (via `voxpupuli-acceptance`) | A real apply on a real node, checked for idempotency | `site-modules/profile/` |

Ruby is pinned to the version in [.ruby-version](.ruby-version) (3.2.8, matching
Puppet Enterprise); CI reads the same file. Note that the two bundles are
separate: [Gemfile](Gemfile) at the root is for Onceover, and
[site-modules/profile/Gemfile](site-modules/profile/Gemfile) is for
rspec-puppet and Beaker.

### 1. Unit tests — rspec-puppet against `site-modules/profile`

rspec-puppet is module-scoped by design; it has no notion of a control repo.
The way around that is to stop treating `site-modules/profile` as "a directory
in a control repo" and start treating it as **a module that happens to live in
a control repo**. It gets its own
[metadata.json](site-modules/profile/metadata.json),
[Gemfile](site-modules/profile/Gemfile),
[Rakefile](site-modules/profile/Rakefile),
[.fixtures.yml](site-modules/profile/.fixtures.yml) and `spec/` directory —
after which the standard Vox Pupuli module toolchain works unmodified, with no
`module_path` surgery in `spec_helper.rb`.

```bash
cd site-modules/profile
bundle install
bundle exec rake validate lint check   # syntax, puppet-lint, rubocop
bundle exec rake parallel_spec         # all unit tests
bundle exec rake spec SPEC=spec/classes/openvox_agent_spec.rb  # just one
```

Lint rules are the `voxpupuli-test` gem defaults — there is deliberately no
`.puppet-lint.rc` or `.rubocop.yml` here.

The trade-off is that dependencies are declared twice: fixtures come from
`.fixtures.yml`, not the control repo's [Puppetfile](Puppetfile), so adding a
module dependency to a profile means updating `.fixtures.yml`, `metadata.json`
**and** the `Puppetfile`. (The other common layout — a single top-level `spec/`
with `c.module_path` pointed at `site-modules`, or parsed out of
[environment.conf](environment.conf) — avoids the duplication but gives up the
per-module Rakefile, the `on_supported_os` matrix from `metadata.json`, and the
ability to reuse Vox Pupuli's shared GitHub workflows.)

Multi-OS coverage comes from `rspec-puppet-facts`: `on_supported_os` generates
fact sets from the `operatingsystem_support` entries in `metadata.json`, so a
platform is only covered once it's listed there *and* facterdb ships facts for
it.

If you'd rather not install Ruby at all, the
[voxbox container](https://github.com/voxpupuli/container-voxbox) runs the same
tasks (its lint rules can drift from the CI bundle, which is authoritative):

```bash
docker run --rm -v $PWD:/repo ghcr.io/voxpupuli/voxbox:8 spec
```

### 2. Compilation tests — Onceover on the whole control repo

Unit tests prove a profile compiles in isolation with facts you supplied by
hand. They say nothing about whether `role::puppet_master` composes cleanly, or
whether the Hiera data in [data/](data/) actually resolves. Onceover covers
exactly that gap: it compiles **every role against representative node
factsets**, exercising the full `role -> profile -> module` chain with this
repo's own Hiera.

```bash
# From the repo root — uses the root Gemfile, not site-modules/profile
bundle install
bundle exec onceover run spec --auto_vendored
bundle exec onceover show repo   # print the parsed test matrix
```

Configuration lives in [spec/](spec/):

- [spec/onceover.yaml](spec/onceover.yaml) — the `test_matrix`: which roles
  compile on which nodes. `role::puppet_master` runs only on
  `puppet.example.com`; the `profile::base`-only roles run on both agents to
  catch RedHat/Debian regressions.
- [spec/factsets/](spec/factsets/) — **real** facts captured from the Vagrant
  VMs, not synthetic ones. Named after each certname so
  `nodes/%{trusted.certname}.yaml` resolves correctly. See
  [spec/factsets/README.md](spec/factsets/README.md) to regenerate.
- [spec/hiera.yaml](spec/hiera.yaml) — an Onceover-only Hiera config that drops
  the eyaml backend, so CI needs no PKCS7 keys. The production root
  [hiera.yaml](hiera.yaml) is untouched.

One wrinkle worth knowing about: core types like `yumrepo` and `cron` come from
modules that ship **vendored with the OpenVox agent** (`yumrepo_core`,
`cron_core`, ...). On real nodes they're on the `$basemodulepath`, so they are
deliberately absent from the `Puppetfile`. Onceover runs against a gem-installed
Puppet that lacks them, so `--auto_vendored` resolves them from the agent's
component manifests and injects them into Onceover's *temporary* Puppetfile
only. The committed cache in [spec/vendored_modules/](spec/vendored_modules/)
lets that work without a GitHub API call at run time; regenerate it with
`bundle exec rake generate_vendor_cache` when the Puppet version changes.

### 3. Acceptance tests — Beaker

Compilation is not application. Beaker provisions a real node, installs
OpenVox, applies a manifest, and re-applies it to prove idempotency.

```bash
cd site-modules/profile
BUNDLE_WITHOUT=development:release bundle install
BEAKER_HYPERVISOR=docker \
BEAKER_PUPPET_COLLECTION=openvox8 \
BEAKER_SETFILE=almalinux9-64 \
  bundle exec rake beaker
```

Tests live in [site-modules/profile/spec/acceptance/](site-modules/profile/spec/acceptance/),
and the whole harness is a `require 'voxpupuli/acceptance/spec_helper_acceptance'`
followed by `configure_beaker` — node definitions come from
`voxpupuli-acceptance`'s built-in setfiles, selected by `BEAKER_SETFILE`. Set
`BEAKER_destroy=no` to keep the container around for debugging.

### 4. The Vagrant environment

The layers above are all disposable. For end-to-end verification against the
real master/agent topology, use the [Vagrant environment](#environment) — the
repo is synced to `/etc/puppetlabs/code/environments/production` on the master,
so changes are live immediately:

```bash
vagrant ssh agent01 -c "sudo /opt/puppetlabs/bin/puppet agent -t"
./scripts/bolt-validate.sh   # Bolt validation plan, from the host
```

## Resources

- [OpenVox Ecosystem Documentation](https://docs.openvoxproject.org/ecosystem/latest/) — the tooling around OpenVox, including the test stack used here
- [OpenVox Project](https://github.com/voxpupuli)
- [Puppet Documentation](https://www.puppet.com/docs/puppet/latest/)
- [Voxbox Container](https://github.com/voxpupuli/container-voxbox)
