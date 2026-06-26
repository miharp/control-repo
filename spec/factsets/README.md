# Onceover factsets

These JSON factsets are **real facts** captured from the Vagrant VMs, so the
control-repo's roles are compiled against the exact platforms they run on:

| Factset                     | VM      | OS                |
| --------------------------- | ------- | ----------------- |
| `puppet.example.com.json`   | puppet  | CentOS Stream 10  |
| `agent01.example.com.json`  | agent01 | CentOS Stream 9   |
| `agent02.example.com.json`  | agent02 | Ubuntu 24.04      |

Real facts (rather than facterdb fact sets) are used because facterdb does not
yet ship a RedHat 10 set, which the puppet master needs.

## Format

Each file is an Onceover factset:

```json
{
  "name":   "<certname>",
  "values": { ...facter output... },
  "trusted": { "certname": "<certname>", ... }
}
```

The `trusted.certname` is what makes Onceover set `let(:node)`, so that
`nodes/%{trusted.certname}.yaml` resolves the per-node Hiera data during the
test compile (this is how the puppet master picks up its version pins and EL10
PostgreSQL overrides).

## Regenerating

When the platforms or installed package versions change, refresh the factsets
from the running VMs:

```bash
for vm in puppet agent01 agent02; do
  vagrant ssh $vm -c \
    "sudo /opt/puppetlabs/bin/puppet facts show --render-as json" \
    > /tmp/${vm}.json
done
```

then wrap each raw facts hash as `{ "name", "values", "trusted" }` (see the
git history of this directory for the wrapping script). The `name` and
`trusted.certname` must equal the node's certname so the Hiera node hierarchy
resolves.
