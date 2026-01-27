#!/bin/bash
# code_content.sh - Returns file content for static catalogs
# Usage: code_content.sh <environment> <code_id> <file_path>
# Called by Puppet Server when resolving file content for static catalogs

set -e

ENVIRONMENT="$1"
CODE_ID="$2"
FILE_PATH="$3"

ENVIRONMENTPATH="/etc/puppetlabs/code/environments"
ENVDIR="${ENVIRONMENTPATH}/${ENVIRONMENT}"

if [ -z "$ENVIRONMENT" ] || [ -z "$CODE_ID" ] || [ -z "$FILE_PATH" ]; then
  echo "Usage: $0 <environment> <code_id> <file_path>" >&2
  exit 1
fi

# Remove any leading slashes from FILE_PATH for safety
FILE_PATH="${FILE_PATH#/}"

# For git-based environments, we can retrieve content from specific commits
if command -v git >/dev/null 2>&1 && [ -d "${ENVDIR}/.git" ]; then
  # Try to retrieve the file from the specified commit
  if git --git-dir "${ENVDIR}/.git" cat-file -e "${CODE_ID}:${FILE_PATH}" 2>/dev/null; then
    git --git-dir "${ENVDIR}/.git" show "${CODE_ID}:${FILE_PATH}"
    exit 0
  fi
fi

# Fall back to reading the file from the filesystem
# This works when the current deployed code matches the code_id
FULL_PATH="${ENVDIR}/${FILE_PATH}"

if [ -f "$FULL_PATH" ]; then
  cat "$FULL_PATH"
  exit 0
fi

echo "File not found: $FILE_PATH in environment $ENVIRONMENT" >&2
exit 1
