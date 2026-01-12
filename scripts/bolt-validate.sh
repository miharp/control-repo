#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MASTER_VM="${BOLT_MASTER_VM:-puppet}"
REMOTE_DIR="${BOLT_REMOTE_DIR:-/etc/puppetlabs/code/environments/production}"
INVENTORY_FILE="${BOLT_INVENTORY_FILE:-inventory.yaml}"
PLAN_NAME="${BOLT_PLAN_NAME:-control_repo::validate}"

vagrant ssh "$MASTER_VM" -c "sudo bash -lc 'cd \"$REMOTE_DIR\" && /opt/puppetlabs/bin/bolt plan run \"$PLAN_NAME\" --inventoryfile \"$INVENTORY_FILE\"'"
