#!/bin/bash
# code_id.sh - Returns a unique code identifier for static catalogs
# Usage: code_id.sh <environment>
# Called by Puppet Server with: code_id_command = /path/to/code_id.sh

set -e

# The environment name is passed as the first argument
ENVIRONMENT="$1"

# Determine the environment path (standard location)
ENVIRONMENTPATH="/etc/puppetlabs/code/environments"
ENVDIR="${ENVIRONMENTPATH}/${ENVIRONMENT}"

if [ ! -d "$ENVDIR" ]; then
  echo "Environment directory not found: $ENVDIR" >&2
  exit 1
fi

# Check for r10k deployment signature first
if [ -f "${ENVDIR}/.r10k-deploy.json" ]; then
  # Extract signature from r10k deploy file
  /opt/puppetlabs/puppet/bin/ruby -rjson -e \
    "puts JSON.parse(File.read('${ENVDIR}/.r10k-deploy.json'))['signature']"
  exit 0
fi

# Fall back to git commit hash
if command -v git >/dev/null 2>&1 && [ -d "${ENVDIR}/.git" ]; then
  git --git-dir "${ENVDIR}/.git" rev-parse HEAD
  exit 0
fi

# Last resort: use timestamp (not ideal for static catalogs)
echo "warning: no git or r10k signature available, using timestamp" >&2
date +%s
