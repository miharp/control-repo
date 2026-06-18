# NetworkManager PR #2 — integration test harness & results

Living integration-test harness for
[voxpupuli/puppet-networkmanager#2](https://github.com/voxpupuli/puppet-networkmanager/pull/2)
(branch `improvements`). Re-run this as the module PR is updated.

## What this branch adds

- **`Puppetfile`** — pulls the module from the PR branch plus its `extlib`
  dependency (r10k does not resolve module deps):
  ```ruby
  mod 'networkmanager',
    git: 'https://github.com/voxpupuli/puppet-networkmanager.git',
    branch: 'improvements'
  mod 'puppet/extlib', '7.5.1'
  ```
- **`site-modules/profile/manifests/networkmanager_test.pp`** — `include
  networkmanager` + one `networkmanager_connection` on a **slaveless bridge**
  (`br-nmtest`), `reapply => false`. A bridge with no enslaved ports carries no
  traffic, so the test never disturbs the agent's real uplink / host-only SSH.
- **`manifests/site.pp`** — classifies `agent01.example.com` (CentOS Stream 9)
  with the test profile. agent02 (Ubuntu) is intentionally excluded: the PR
  dropped Debian/Ubuntu from `metadata.json`.

## How to run

```bash
vagrant up puppet agent01
# pull the module(s) onto the master
vagrant ssh puppet -c 'cd /etc/puppetlabs/code/environments/production \
  && sudo /opt/puppetlabs/puppet/bin/r10k puppetfile install -v'
# apply on the agent
vagrant ssh agent01 -c 'sudo /opt/puppetlabs/bin/puppet agent -t'
# cleanup between iterations
vagrant ssh agent01 -c 'sudo nmcli connection delete nm-pr2-test'
```

## Environment

| | |
| --- | --- |
| Agent | agent01.example.com — CentOS Stream 9 (Parallels) |
| Master | puppet.example.com — CentOS Stream 10, OpenVox Server |
| nmcli | 1.54.4-1.el9 |
| Module ref | `voxpupuli/puppet-networkmanager@improvements` (PR #2 head `bdeb997`) |
| Tested | 2026-06-18 |

---

## Results — 2 blocking runtime bugs found

Both are net-new in this PR (the custom `set` and the route support) and are not
caught by the existing unit tests.

### Bug A — new connections can't be created (`set` dispatches to `modify`, not `add`)

First run against a host where the profile does **not** exist. Note it logs
`Updating` (not `Creating`) and then fails:

```text
Info: Using environment 'production'
Info: Retrieving pluginfacts
Info: Retrieving plugin
Notice: /File[.../lib/facter/nm_all_connections.rb]/ensure: defined content ...
Notice: /File[.../lib/puppet/type/networkmanager_connection.rb]/ensure: defined content ...
Info: Caching catalog for agent01.example.com
Info: Applying configuration version 'a38e2dc63243b3648c756c1d7bd8c6421a456caf'
Error: networkmanager_connection: Error fetching NetworkManager connection 'nm-pr2-test': Execution of '/bin/nmcli -t connection show nm-pr2-test' returned 10: Error: nm-pr2-test - no such connection profile.
Notice: /Stage[main]/Profile::Networkmanager_test/Networkmanager_connection[nm-pr2-test]/ensure: defined 'ensure' as 'present'
Notice: networkmanager_connection: Updating 'nm-pr2-test'
Error: networkmanager_connection: Failed to apply networkmanager_connection changes: Execution of '/bin/nmcli connection modify nm-pr2-test connection.interface-name br-nmtest ipv4.method manual ipv4.addresses 10.99.0.10/24 ipv4.dns 1.1.1.1 ipv4.gateway 10.99.0.1 ipv4.routes 10.50.0.0/24 10.99.0.254 100 ipv6.method ignore' returned 10: Error: unknown connection 'nm-pr2-test'.
Error: /Stage[main]/Profile::Networkmanager_test/Networkmanager_connection[nm-pr2-test]: Could not evaluate: Execution of '/bin/nmcli connection modify nm-pr2-test ...' returned 10: Error: unknown connection 'nm-pr2-test'.
Notice: Applied catalog in 0.23 seconds
```

`get` reports the resource absent correctly:

```text
$ sudo puppet resource networkmanager_connection nm-pr2-test
Error: networkmanager_connection: Error fetching NetworkManager connection 'nm-pr2-test': ... no such connection profile.
networkmanager_connection { 'nm-pr2-test':
  ensure  => 'absent',
  reapply => false,
}
```

…but the hand-rolled `set` takes the **update** branch for an absent resource, so
`nmcli connection add` is never reached. Confirmed it is *only* the create
dispatch by pre-creating an empty profile by hand — the `modify`/update path then
applies every property correctly:

```text
$ sudo nmcli connection add type bridge con-name nm-pr2-test ifname br-nmtest
Connection 'nm-pr2-test' (10665dc6-9cd7-4a42-8d34-1eeab2dbb113) successfully added.

# next puppet run:
Notice: .../ipv4_method: ipv4_method changed 'auto' to 'manual' (corrective)
Notice: .../ipv4_addresses: ipv4_addresses changed  to ['10.99.0.10/24'] (corrective)
Notice: .../ipv4_dns: ipv4_dns changed  to ['1.1.1.1'] (corrective)
Notice: .../ipv4_gateway: ipv4_gateway changed  to '10.99.0.1' (corrective)
Notice: .../ipv4_routes: ipv4_routes changed [] to [ ... ]
Notice: .../ipv6_method: ipv6_method changed 'auto' to 'ignore' (corrective)
Notice: networkmanager_connection: Updating 'nm-pr2-test'
Notice: Applied catalog in 0.22 seconds
```

**Root cause:** the `is.empty? || is[:ensure] == 'absent'` dispatch in `set`
mis-evaluates in the catalog-apply path (the `ensure` comparison doesn't match
what the framework passes as `is`).
**Suggested fix:** normalize the comparison (`is[:ensure].to_s == 'absent'`), or
drop the custom `set` and use `SimpleProvider`'s `create`/`update`/`delete`
dispatch (adding `reapply` there).

### Bug B — routes break the type schema (idempotency impossible)

Once the connection has any `ipv4_routes`/`ipv6_routes`, **every** subsequent run
fails on read:

```text
Error: /Stage[main]/Profile::Networkmanager_test/Networkmanager_connection[nm-pr2-test]: Could not evaluate: Provider returned data that does not match the Type Schema for `networkmanager_connection[nm-pr2-test]`
 Value type mismatch:
    * ipv4_routes: [{:destination=>"10.50.0.0/24", :next_hop=>"10.99.0.254", :metric=>100}] (index 0 expects a Struct[{'destination' => Pattern[/\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/], Optional['next_hop'] => Pattern[/\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/], Optional['metric'] => Integer[0]}] value, got Hash[Runtime[ruby, 'Symbol'], Variant[Integer[100, 100], Enum['10.50.0.0/24', '10.99.0.254']]])
```

The applied nmcli state is correct, so this is purely a read/`get` typing bug:

```text
$ sudo nmcli -t connection show nm-pr2-test | grep -iE '^ipv4|^ipv6.method'
ipv4.method:manual
ipv4.dns:1.1.1.1
ipv4.addresses:10.99.0.10/24
ipv4.gateway:10.99.0.1
ipv4.routes:10.50.0.0/24 10.99.0.254 100
ipv6.method:ignore
```

**Root cause:** the type `Struct` uses **string** keys (`'destination'`,
`'next_hop'`, `'metric'`) but `parse_route_entry` (in `get`) builds the hash with
**symbol** keys. RSAPI validates `get` output against the schema and rejects it.
The write side (`format_route_entry`) already tolerates both key styles, so only
the read path is wrong.
**Suggested fix:** have `parse_route_entry` emit string keys to match the
`Struct`.

## What works

- Custom type/provider + all six facts pluginsync and load cleanly.
- `extlib` resolves; catalog compiles.
- The `modify` path applies `ipv4.method`/`addresses`/`dns`/`gateway`/`routes`
  and `ipv6.method` correctly.
- `general_state` normalization is right (`activating` → `connecting`).

## Suggested module-side regression tests

- A provider unit test that round-trips a route through `get` and validates the
  result against the real type schema (would catch Bug B).
- A `create` (absent → present) provider test (would catch Bug A).
