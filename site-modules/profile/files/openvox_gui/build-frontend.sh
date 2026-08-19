#!/bin/bash
# Managed by Puppet - do not edit
#
# Builds the openvox-gui React frontend. On aarch64 (Parallels on Apple
# Silicon) npm misses the rollup native binding on the first install
# (https://github.com/npm/cli/issues/4828), so it is added explicitly in a
# second step before building. Stamps frontend/.built-version on success so
# Puppet re-runs the build only when the checked-out VERSION changes.
set -e
cd /opt/openvox-gui-src/frontend
npm install
if [ "$(uname -m)" = "aarch64" ]; then
  npm install @rollup/rollup-linux-arm64-gnu
fi
npm run build
cp ../VERSION .built-version
