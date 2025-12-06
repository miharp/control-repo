# The base profile should include component modules that will be on all nodes
class profile::base {
  notify { 'Base profile applied': }
}
