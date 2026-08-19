# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Puppet control repository for OpenVox (a Vox Pupuli fork of Puppet). It manages a development environment with an OpenVox Server (Puppet master) running on CentOS Stream 10 and agents running on CentOS Stream 9 and Ubuntu 24.04.

## Common Commands

### Ruby Setup (for local testing)

This project uses Ruby 3.2.8 (pinned in `.ruby-version`) to match Puppet Enterprise. Both local development and CI use the same version.

```bash
rbenv install 3.2.8    # Install the required Ruby version
ruby -v                # Verify: should show ruby 3.2.8
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

Lint rules come from the `voxpupuli-test` gem defaults. There is no `.puppet-lint.rc` or `.rubocop.yml` in this repo.

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

### Control-Repo Testing with Onceover

[Onceover](https://github.com/voxpupuli/onceover) compiles **every role** against
representative node factsets, exercising the full `role -> profile -> module`
composition with the control-repo's own Hiera data. This complements the
per-module rspec-puppet suite (which tests profiles in isolation). It runs in
CI (the `Onceover` job in `.github/workflows/puppet.yml`) and is authoritative
for role-level compilation.

```bash
# From the control-repo root (uses the root Gemfile, not site-modules/profile)
bundle install
bundle exec onceover run spec --auto_vendored   # Compile all roles against their factsets
bundle exec onceover show repo                  # Show the parsed test matrix
```

Config and fixtures live in `spec/`:

- `spec/onceover.yaml` — which roles compile on which nodes (`test_matrix`).
  `role::puppet_master` runs only on `puppet.example.com`; the `profile::base`
  roles run on both agents.
- `spec/factsets/*.json` — **real** facts captured from the Vagrant VMs (EL10,
  EL9, Ubuntu 24.04). See `spec/factsets/README.md` to regenerate them.
- `spec/hiera.yaml` — Onceover-only Hiera config. It drops the eyaml backend so
  no PKCS7 keys are needed (the real `keys/*.pem` are gitignored / absent in CI)
  and supplies the `profile::base::eyaml_secret` canary as plaintext from
  `spec/data/common.yaml`. Real per-node and common data still load from `data/`.
  The production root `hiera.yaml` (with eyaml intact) is untouched.
- `spec/vendored_modules/*.json` — cached resolution for `--auto_vendored`.

Core resource types like `yumrepo` and `cron` come from modules that ship
**vendored with the OpenVox agent** (`yumrepo_core`, `cron_core`, ...). On real
nodes they are on the `$basemodulepath`, so they are deliberately **not** in the
Puppetfile. Onceover runs against a gem-installed Puppet that lacks them, so
`--auto_vendored` resolves them from the agent's component manifests and injects
them into Onceover's *temporary* Puppetfile only. The committed cache in
`spec/vendored_modules/` lets this work without a GitHub API call at run time;
regenerate it with `bundle exec rake generate_vendor_cache` if the Puppet
version changes.

### Acceptance Testing with Beaker

[Beaker](https://github.com/voxpupuli/beaker) (via `voxpupuli-acceptance`)
provisions a real node, installs OpenVox, applies a manifest, and re-applies it
to prove idempotency. It runs in CI (the `Beaker` job in
`.github/workflows/puppet.yml`) and is authoritative for "does this actually
apply", which neither rspec-puppet nor Onceover can answer.

```bash
cd site-modules/profile
BUNDLE_WITHOUT=development:release bundle install   # needs the system_tests group

# Add BEAKER_destroy=no to keep the container alive for debugging
BEAKER_HYPERVISOR=docker \
BEAKER_PUPPET_COLLECTION=openvox8 \
BEAKER_SETFILE=almalinux9-64 \
  bundle exec rake beaker
```

- Tests live in `site-modules/profile/spec/acceptance/`.
- `spec/spec_helper_acceptance.rb` is just
  `require 'voxpupuli/acceptance/spec_helper_acceptance'` + `configure_beaker`.
  Node definitions come from `voxpupuli-acceptance`'s built-in setfiles,
  selected by `BEAKER_SETFILE` — there are no local nodeset files.
- Beaker deps are in the `system_tests` group of
  `site-modules/profile/Gemfile`, which is **not** installed by a plain
  `bundle install` in CI (CI sets `BUNDLE_WITHOUT=development:release`).
- `spec/acceptance/example_spec.rb` is a smoke test using the empty
  `profile::example` class, so the harness itself is verified without depending
  on external repos. Profiles that need real package repos should be added
  deliberately.

### Module Management

```bash
# Install modules from Puppetfile (on the Puppet master)
/opt/puppetlabs/puppet/bin/r10k puppetfile install
```

### Vagrant Development Environment

Vagrant uses the **Parallels provider** (not VirtualBox). VMs provision sequentially by default (`VAGRANT_NO_PARALLEL=1`) due to puppetserver restart sensitivity.

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

- **site-modules/role/** - Node classification (one role per node type)
- **site-modules/profile/** - Technology-specific configurations composed into roles
- **modules/** - External modules from Puppet Forge (managed via Puppetfile)

Roles include profiles, profiles include component modules. Example: `role::puppet_master` includes `profile::base`, `profile::openvox_server`, `profile::openvoxdb`, `profile::openbolt`, `profile::static_catalogs`, `profile::openvoxview`, `profile::openvox_gui`.

### Current Profiles

| Profile | Purpose |
| --- | --- |
| `base` | Core config for all nodes (chrony, firewall, OpenVox repo, sudo) |
| `openvox_agent` | Manages openvox-agent package with OS-specific versioning |
| `openvox_server` | Manages openvox-server package on the Puppet master |
| `openvoxdb` | Configures OpenVoxDB via voxpupuli/puppet-openvoxdb (Git) |
| `openbolt` | Installs OpenBolt (Bolt CLI) package |
| `openvoxview` | Installs OpenVoxView, a web UI for browsing reports/catalogs from the local PuppetDB |
| `openvox_gui` | Installs [OpenVox GUI](https://github.com/cvquesty/openvox-gui) (port 4567), a management console (CA, orchestration, PQL) that runs alongside OpenVoxView; wraps the upstream installer with a pinned release tag |
| `static_catalogs` | Enables Puppet Server static catalog optimization (code_id/code_content scripts) |
| `example` | Intentionally empty; used as the Beaker smoke-test subject |

### Hiera Data

- **hiera.yaml** - Hierarchy configuration with eyaml (encrypted) and yaml backends
- **data/** - Hiera data files
  - `nodes/%{trusted.certname}.yaml` - Per-node data
  - `nodes/%{trusted.certname}.eyaml` - Per-node secrets (e.g. the OpenVox GUI admin password)
  - `common.yaml` - Default values (OpenVox release number, agent version)
- **keys/** - eyaml PKCS7 keys (not committed, see keys/README.md for generation)

Node-specific hiera data (e.g., `data/nodes/puppet.example.com.yaml`) pins server versions and configures PostgreSQL repository management for OpenVoxDB.

### Module Path (defined in environment.conf)

1. `site-modules/` - Local modules (role, profile, adhoc)
2. `modules/` - External modules (Forge and Git-sourced via Puppetfile)
3. `$basemodulepath` - System modules

### Bolt Project

- **bolt-project.yaml** - Project configuration
- **inventory.yaml** - Target inventory for agents (SSH transport, vagrant user)
- **plans/** - Bolt plans (e.g., `control_repo::validate`)
- **site-modules/adhoc/tasks/** - Bolt tasks

## Vagrant Environment

| VM | Hostname | IP | OS | Description |
| --- | --- | --- | --- | --- |
| puppet | puppet.example.com | 192.168.56.10 | CentOS Stream 10 | OpenVox Server + PuppetDB |
| agent01 | agent01.example.com | 192.168.56.11 | CentOS Stream 9 | OpenVox agent |
| agent02 | agent02.example.com | 192.168.56.12 | Ubuntu 24.04 | OpenVox agent |

The control-repo is synced to `/etc/puppetlabs/code/environments/production` on the Puppet master.

## CentOS Stream 10 Notes (puppet VM)

- **PostgreSQL 16**: EL10's AppStream ships PostgreSQL 16. The `puppet-postgresql` module doesn't have an EL10 entry in its `default_version` map, so without overrides it falls into the PGDG code path with versioned paths (`/var/lib/pgsql/16/`, `/usr/pgsql-16/bin`, `postgresql-16` service). The AppStream layout uses unversioned paths (`/var/lib/pgsql/data`, `/usr/bin`, `postgresql`). Override `postgresql::globals` in hiera to force the AppStream layout (see `data/nodes/puppet.example.com.yaml`).
- **DNF5 / no modularity**: EL10 ships DNF5, which has dropped the module system. Always set `manage_dnf_module: false` for any module that tries to enable a DNF module stream (e.g., `openvoxdb::manage_dnf_module: false`).
- **OpenVox repo**: Use the `el-10` release RPM (`openvox8-release-el-10.noarch.rpm`), not the `el-9` one.

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

### Test Dependencies

- `.fixtures.yml` pulls forge modules (inifile, stdlib, etc.) and the
  `puppet-openvoxdb` and `puppet-openvoxview` modules from Git, then symlinks
  the profile module. Fixtures are resolved from `.fixtures.yml`, **not** the
  control-repo `Puppetfile`, so adding a module dependency to a profile means
  updating **three** files: `metadata.json`, `.fixtures.yml`, and `Puppetfile`.
- `metadata.json` currently lists `operatingsystem_support` for RedHat 9, RedHat 10, and Ubuntu 24.04. The `on_supported_os` helper in tests only generates facts for OSes listed there. RedHat 10 fact sets are not yet in facterdb, so test coverage for that platform will appear automatically once facterdb ships them.
- `site-modules/profile/spec/unit/hiera_eyaml_spec.rb` generates throwaway PKCS7 keypairs at test time (no private keys stored in repo).

### Test Coverage

Three layers, each covering what the others cannot. All three run in CI on
every PR; see the README's Testing section for the shareable write-up.

| Layer | Tool | Scope | Run from |
| --- | --- | --- | --- |
| Unit | rspec-puppet (`voxpupuli-test`) | Each profile class in isolation | `site-modules/profile/` |
| Compilation | Onceover | Every role, against real node facts + repo Hiera | repo root |
| Acceptance | Beaker (`voxpupuli-acceptance`) | Real apply on a real node, idempotency | `site-modules/profile/` |

Note the two separate bundles: the root `Gemfile` is for Onceover only;
`site-modules/profile/Gemfile` covers rspec-puppet and Beaker.

Profiles with spec tests: `openvox_agent`, `openvoxdb`, `static_catalogs`,
`base`, `openvox_server`, `openbolt`, `openvoxview`, `openvox_gui`. All profiles except
`example` (the empty Beaker smoke-test subject) have spec tests.

Roles are covered by Onceover (see "Control-Repo Testing with Onceover" above):
`puppet_master`, `database_server`, `webserver`, `example` all compile against
real-fact node factsets.

Acceptance coverage is currently the `profile::example` smoke test only (see
"Acceptance Testing with Beaker" above).
