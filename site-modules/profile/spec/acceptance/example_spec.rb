# frozen_string_literal: true

require 'spec_helper_acceptance'

# Smoke test: proves the acceptance harness works end to end (node build,
# OpenVox install, module install, idempotent apply) using the empty
# profile::example class so the result doesn't depend on external repos.
describe 'profile::example' do
  it_behaves_like 'an idempotent resource' do
    let(:manifest) do
      <<-PUPPET
      include profile::example
      PUPPET
    end
  end
end
