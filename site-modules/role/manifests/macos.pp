# @summary A macOS agent (the throwaway Tart VMs from tart/mac.sh).
#
# profile::base manages Linux services and repositories, so macOS nodes get
# only the run scheduler.
class role::macos {
  include profile::puppet_run_scheduler
}
