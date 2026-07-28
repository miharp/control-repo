#!/bin/bash
# code_content.sh - Returns file content for a specific code_id (static catalogs).
# Usage: code_content.sh <environment> <code_id> <file_path>
# Called by Puppet Server for /puppet/v3/static_file_content requests.
#
# Contract: return the bytes of <file_path> *as they were at <code_id>*, or exit
# non-zero. The code_id is the identity of a version; answering with any other
# version's bytes is the exact failure static catalogs exist to prevent, so this
# script never falls back to reading the current working tree. If git cannot
# produce the file at that commit, we fail loudly and let the agent run error
# rather than silently apply mismatched content.
#
# This means content is served only for files tracked in the control repo. A
# file sourced from a module that r10k installed from the Puppetfile is in no
# commit here, so it cannot be served this way; that is the limit of a git-based
# implementation, and the reason resolved-tree distribution (codavox) exists.

set -euo pipefail

ENVIRONMENT="${1:-}"
CODE_ID="${2:-}"
FILE_PATH="${3:-}"

if [ -z "$ENVIRONMENT" ] || [ -z "$CODE_ID" ] || [ -z "$FILE_PATH" ]; then
  echo "Usage: $0 <environment> <code_id> <file_path>" >&2
  exit 1
fi

ENVDIR="/etc/puppetlabs/code/environments/${ENVIRONMENT}"

# Strip any leading slash; git object paths are repo-relative.
FILE_PATH="${FILE_PATH#/}"

if [ ! -d "${ENVDIR}/.git" ]; then
  echo "code_content: ${ENVDIR} is not a git checkout; cannot serve content at a code_id" >&2
  exit 1
fi

# git show resolves <commit>:<repo-relative-path>, and exits non-zero (taking us
# with it, under set -e) when the path is untracked at that commit or escapes
# the repo. No filesystem fallback: a miss must be an error, not stale content.
exec git --git-dir "${ENVDIR}/.git" show "${CODE_ID}:${FILE_PATH}"
