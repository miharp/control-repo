#!/bin/bash
# macOS agents for the Vagrant lab, as throwaway Tart VMs.
#
# Tart VMs cannot reach the Parallels networks, only the host, so each VM maps
# puppet.example.com to its gateway (the host) and reaches the server through
# a Parallels NAT forward of host port 8140 to the master, which `up` creates.
# (A Vagrant forwarded_port cannot do this on macOS 27: Vagrant's collision
# check sees every host port as in use.) The master autosigns.
#
# usage:
#   tart/mac.sh up <name> [--os 26|15] [--agent <version>]
#   tart/mac.sh down <name>
#   tart/mac.sh ssh <name>
#   tart/mac.sh run <name> <command...>
#   tart/mac.sh list
#   tart/mac.sh forward on|off
#
# The certname is <name>.example.com. --agent defaults to the newest 8.x.
# The forward also opens 8140 on the host's LAN address; `forward off`
# removes it.
set -euo pipefail

tart=$(command -v tart || echo "$HOME/Applications/tart.app/Contents/MacOS/tart")
here=$(cd "$(dirname "$0")" && pwd)
rule="tart-puppet-8140"

# (Re)creates the NAT rule for the current puppet VM; its id changes whenever
# the VM is destroyed and rebuilt.
cmd_forward() {
  prlsrvctl net set Shared --nat-tcp-del "$rule" >/dev/null 2>&1 || true
  if [ "$1" = on ]; then
    local id
    id=$(cat "$here/../.vagrant/machines/puppet/parallels/id")
    prlsrvctl net set Shared --nat-tcp-add "$rule,8140,$id,8140"
  fi
}

image_for() {
  case $1 in
    26) echo ghcr.io/cirruslabs/macos-tahoe-base:latest ;;
    15) echo ghcr.io/cirruslabs/macos-sequoia-base:latest ;;
    *) echo "unknown macOS version: $1 (use 26 or 15)" >&2; exit 1 ;;
  esac
}

# Runs a command in the VM as admin through the Tart guest agent. The agent
# starts commands with a bare environment; without LANG, Facter fails on the
# UTF-8 computer name in system_profiler output.
in_vm() {
  local name=$1; shift
  "$tart" exec "$name" /bin/bash -c "export PATH=/usr/bin:/bin:/usr/sbin:/sbin LANG=en_US.UTF-8; $*"
}

wait_for_vm() {
  local name=$1
  for _ in $(seq 60); do
    in_vm "$name" true >/dev/null 2>&1 && return 0
    sleep 3
  done
  echo "$name did not come up" >&2
  exit 1
}

cmd_up() {
  local name=$1; shift
  local os=26 agent=8.28.1
  while [ $# -gt 0 ]; do
    case $1 in
      --os) os=$2; shift 2 ;;
      --agent) agent=$2; shift 2 ;;
      *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
  done
  local collection="openvox${agent%%.*}"
  local dmg="openvox-agent-${agent}-1.macos.all.arm64.dmg"

  cmd_forward on
  "$tart" clone "$(image_for "$os")" "$name"
  nohup "$tart" run --no-graphics "$name" >/dev/null 2>&1 &
  wait_for_vm "$name"

  in_vm "$name" "set -e
    gw=\$(route -n get default | awk '/gateway:/ {print \$2}')
    [ -n \"\$gw\" ] || { echo 'no default gateway in the VM' >&2; exit 1; }
    echo \"\$gw puppet.example.com puppet\" | sudo tee -a /etc/hosts >/dev/null
    sudo scutil --set HostName $name.example.com
    curl -fsSL -o /tmp/$dmg https://downloads.voxpupuli.org/mac/$collection/$dmg
    hdiutil attach /tmp/$dmg -nobrowse -quiet -mountpoint /tmp/openvox-dmg
    sudo installer -pkg /tmp/openvox-dmg/*.pkg -target / >/dev/null
    hdiutil detach /tmp/openvox-dmg -quiet
    sudo /opt/puppetlabs/bin/puppet config set server puppet.example.com --section main
    sudo /opt/puppetlabs/bin/puppet config set certname $name.example.com --section main"

  # 0 = no changes, 2 = changes applied; anything else is a failure.
  set +e
  in_vm "$name" "sudo /opt/puppetlabs/bin/puppet agent -t --detailed-exitcodes"
  local rc=$?
  set -e
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
    echo "first agent run on $name failed (exit $rc)" >&2
    exit "$rc"
  fi
  echo "$name is up: $("$tart" ip "$name"), certname $name.example.com, agent $agent"
}

cmd_down() {
  local name=$1
  "$tart" stop "$name" 2>/dev/null || true
  "$tart" delete "$name"
  # Forget the node on the master so the name can be reused.
  (cd "$here/.." && vagrant ssh puppet -c "sudo /opt/puppetlabs/bin/puppetserver ca clean --certname $name.example.com; sudo /opt/puppetlabs/bin/puppet node deactivate $name.example.com" 2>/dev/null) || true
}

cmd_ssh() {
  # The cirruslabs images log in as admin/admin.
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "admin@$("$tart" ip "$1")"
}

case ${1:-} in
  up) shift; cmd_up "$@" ;;
  down) cmd_down "$2" ;;
  ssh) cmd_ssh "$2" ;;
  run) name=$2; shift 2; in_vm "$name" "$*" ;;
  list) "$tart" list | awk 'NR == 1 || $1 == "local"' ;;
  forward) cmd_forward "$2" ;;
  *) awk 'NR > 1 && !/^#/ {exit} NR > 1 {sub(/^# ?/, ""); print}' "$0"; exit 1 ;;
esac
