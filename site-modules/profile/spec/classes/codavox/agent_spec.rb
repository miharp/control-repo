# frozen_string_literal: true

require 'spec_helper'

describe 'profile::codavox::agent' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      # In the control repo this comes from data/common.yaml; the spec has no
      # hiera, so supply it the same way the class receives it.
      let(:pre_condition) do
        "class { 'codavox': agent_publisher => 'https://puppet.example.com:8150' }"
      end

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('codavox::agent') }

        # The whole point of the default: an agent that converges this node
        # without touching how OpenVox Server compiles catalogs. Wiring before
        # the agent has deployed code fails every compile.
        it { is_expected.not_to contain_class('codavox::server') }
      end

      context 'with wire_server enabled' do
        let(:params) { { wire_server: true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('codavox::server') }

        # Nothing else on a compiler declares this service — profile::openvox_server
        # manages only the package — so codavox has to, or the wiring change
        # restarts nothing.
        it { is_expected.to contain_service('puppetserver') }
      end
    end
  end
end
