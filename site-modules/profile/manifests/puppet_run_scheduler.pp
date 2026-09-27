# @summary Runs the agent from cron at fixed times instead of as a daemon.
#
# Thin wrapper around puppet_run_scheduler: a root cron job runs
# `puppet agent --onetime` at times spread across the interval by fqdn_rand,
# and the puppet service is stopped and disabled. Every run is a fresh
# process, which on macOS 26 avoids the crash of the long-running 8.x
# daemon's forked runs (OpenVoxProject/openvox#538).
#
# When the daemon applies this for the first time it stops itself at
# Service['puppet']; that run is cut short and cron takes over.
#
# @param run_interval
#   How often the agent runs.
class profile::puppet_run_scheduler (
  Puppet_run_scheduler::Run_interval $run_interval = '30m',
) {
  class { 'puppet_run_scheduler':
    run_interval => $run_interval,
  }

  # cron on macOS starts jobs without LANG, and Facter then fails on the
  # UTF-8 computer name in system_profiler output and drops most of that
  # fact. Drop this once voxpupuli/puppet-puppet_run_scheduler#28, which
  # sets it in the module, is merged and pinned.
  if $facts['os']['family'] == 'Darwin' {
    Cron <| title == 'puppet-run-scheduler' |> {
      environment => ['LANG=en_US.UTF-8'],
    }
  }
}
