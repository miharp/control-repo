# frozen_string_literal: true

require 'spec_helper'

describe 'profile::codavox::publisher' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      # In the control repo this comes from data/nodes/puppet.example.com.yaml.
      # codavox refuses to start a publisher with no staging directory, so the
      # class cannot compile without it either.
      let(:pre_condition) do
        "class { 'codavox': staging => '/etc/puppetlabs/code/environments' }"
      end

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('codavox::publish') }

        # A compiler that cannot reach the publisher converges on nothing, and
        # the failure looks like a codavox bug rather than a firewall rule.
        it {
          is_expected.to contain_firewall('100 allow codavox publisher')
            .with_dport(8150)
            .with_proto('tcp')
            .with_jump('ACCEPT')
        }
      end

      context 'with a non-default port' do
        let(:params) { { port: 9150 } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_firewall('100 allow codavox publisher').with_dport(9150) }
      end
    end
  end
end
