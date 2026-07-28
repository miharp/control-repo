#!/bin/bash
# code_id.sh - Returns the code_id (version identity) for an environment.
# Usage: code_id.sh <environment>
# Called by Puppet Server for every static catalog compile, once per compile.
#
# The code_id must be deterministic for a given deployed version and must match
# what code_content.sh can resolve. Both derive from the same commit:
#   - r10k deploy: the signature recorded in .r10k-deploy.json (a commit sha)
#   - otherwise:   the checked-out git HEAD
# There is no timestamp last resort. A time-based code_id names a version that
# nothing can serve and differs on every compiler, which is worse than failing.

set -euo pipefail

ENVIRONMENT="${1:-}"
if [ -z "$ENVIRONMENT" ]; then
  echo "Expected an environment" >&2
  exit 1
fi

ENVDIR="/etc/puppetlabs/code/environments/${ENVIRONMENT}"
if [ ! -d "$ENVDIR" ]; then
  echo "Environment directory not found: $ENVDIR" >&2
  exit 1
fi

# Prefer the r10k deploy signature so the id matches exactly what r10k deployed.
if [ -f "${ENVDIR}/.r10k-deploy.json" ]; then
  exec /opt/puppetlabs/puppet/bin/ruby -rjson -e \
    "puts JSON.parse(File.read('${ENVDIR}/.r10k-deploy.json')).fetch('signature')"
fi

# Otherwise use git HEAD. code_content.sh resolves content at this same commit.
if command -v git >/dev/null 2>&1 && [ -d "${ENVDIR}/.git" ]; then
  exec git --git-dir "${ENVDIR}/.git" rev-parse HEAD
fi

echo "code_id: ${ENVDIR} has neither an r10k deploy signature nor a git checkout" >&2
exit 1
