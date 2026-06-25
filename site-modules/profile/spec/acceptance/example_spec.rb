# frozen_string_literal: true

require 'spec_helper_acceptance'

# Smoke test: proves the acceptance harness works end to end (node build,
# OpenVox install, module install, idempotent apply) using the empty
# profile::example class so the result doesn't depend on external repos.
describe 'profile::example' do
  it 'works idempotently with no errors' do
    pp = <<-PUPPET
    include profile::example
    PUPPET

    # Run it twice and test for idempotency
    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes: true)
  end
end
