#!/bin/bash
# Managed by Puppet - do not edit
# Builds the openvox-gui React frontend with the ARM64 rollup workaround.
# See https://github.com/npm/cli/issues/4828
set -e
cd /opt/openvox-gui-src/frontend
npm install
npm install @rollup/rollup-linux-arm64-gnu
npm run build
