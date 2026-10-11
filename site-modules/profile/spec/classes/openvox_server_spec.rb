# frozen_string_literal: true

require 'spec_helper'

describe 'profile::openvox_server' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge(aio_agent_version: '8.30.0') }
      let(:params) { { version: '8.17.0', release: 8 } }

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_class('openvox_server')
          .with_collection('openvox8')
          .with_package_version('8.17.0')
          .with_manage_agent(false)
      end

      it { is_expected.not_to contain_class('openvox_agent') }
      it { is_expected.to contain_service('puppetserver').with_ensure('running') }

      if os_facts[:os]['family'] == 'RedHat'
        it { is_expected.to contain_package('openvox-server').with_ensure("8.17.0-1.el#{os_facts[:os]['release']['major']}") }
      else
        it { is_expected.to contain_package('openvox-server').with_ensure(%r{\A8\.17\.0-1\+}) }
      end

      it { is_expected.to contain_package('r10k').with_ensure('installed').with_provider('puppet_gem') }

      context 'with the agent package managed in the same catalog' do
        let(:pre_condition) { "package { 'openvox-agent': ensure => '9.0.0' }" }

        it 'lets the package manager move the server (and its agent dependency) first' do
          is_expected.to contain_package('openvox-server').that_comes_before('Package[openvox-agent]')
        end

        it 'installs r10k into the Ruby of the agent it just installed' do
          is_expected.to contain_package('openvox-agent').that_comes_before('Package[r10k]')
        end
      end

      context 'on the openvox9 branch' do
        let(:facts) { os_facts.merge(aio_agent_version: '9.0.0') }
        let(:params) { { version: '9.0.1', release: 9 } }

        it { is_expected.to contain_class('openvox_server').with_collection('openvox9').with_package_version('9.0.1') }
      end

      context 'with java_package' do
        let(:params) { super().merge(java_package: 'java-25-openjdk-headless') }

        it { is_expected.to contain_package('java-25-openjdk-headless').that_comes_before('Package[openvox-server]') }
      end
    end
  end
end
