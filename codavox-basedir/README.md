# codavox basedir

This is the directory `codavox publish` seals on the primary — its `basedir`, in
r10k's sense: one subdirectory per environment.

**It deliberately does not contain `production`.** The `production` environment is
the Vagrant synced checkout of this repo, and it is the dev environment: edits to
it must show up on the next agent run with nothing in between. Pointing codavox at
it would mean either depending on r10k to deploy it, or sealing a working tree
full of build artifacts — `.onceover/` alone holds rspec-puppet fixture symlinks
whose targets are absolute macOS host paths, which codavox correctly refuses to
unpack.

So codavox gets its own environment instead, and the dev loop keeps its
properties:

| environment | served from | changes appear |
|---|---|---|
| `production` | the synced checkout, straight from `environmentpath` | immediately, no deploy step |
| `codavox_test` | sealed here, distributed to compilers by codavox | on the next reseal + agent poll |

Because this directory is *also* inside the synced folder, editing `codavox_test`
here is still immediate on the primary — it just needs a reseal to reach a
compiler, which is the thing being tested:

```console
vagrant ssh puppet -c 'sudo systemctl reload codavox-publish'
```

Then watch it land:

```console
vagrant ssh puppet     -c 'sudo codavox compilers'
vagrant ssh compiler   -c 'codavox-code-id codavox_test'
```
