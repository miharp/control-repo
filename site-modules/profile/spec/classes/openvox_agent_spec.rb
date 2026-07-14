# frozen_string_literal: true

require 'spec_helper'

describe 'profile::openvox_agent' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { version: '1.0.0' } }

      it { is_expected.to compile }

      if os_facts[:os]['name'] == 'Ubuntu'
        it { is_expected.to contain_class('apt::update') }
        it {
          is_expected.to contain_package('openvox-agent')
            .that_requires('Class[apt::update]')
        }
      end

      context 'with source URL (pre-release install)' do
        if os_facts[:os]['family'] == 'RedHat'
          let(:params) do
            {
              version: '9.0.0.alpha2-1.el9',
              source: 'https://s3.osuosl.org/openvox-artifacts/openvox-agent/9.0.0.alpha2/openvox-agent-9.0.0.alpha2-1.el9.aarch64.rpm',
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_package('openvox-agent')
              .with_ensure('9.0.0.alpha2-1.el9')
              .with_source('https://s3.osuosl.org/openvox-artifacts/openvox-agent/9.0.0.alpha2/openvox-agent-9.0.0.alpha2-1.el9.aarch64.rpm')
              .with_provider('rpm')
          }
        else
          let(:params) do
            {
              version: '9.0.0.alpha2-1+ubuntu24.04',
              source: 'https://s3.osuosl.org/openvox-artifacts/openvox-agent/9.0.0.alpha2/openvox-agent_9.0.0.alpha2-1+ubuntu24.04_arm64.deb',
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_file('/var/cache/openvox-agent_9.0.0.alpha2-1+ubuntu24.04.deb')
              .with_source('https://s3.osuosl.org/openvox-artifacts/openvox-agent/9.0.0.alpha2/openvox-agent_9.0.0.alpha2-1+ubuntu24.04_arm64.deb')
          }

          it {
            is_expected.to contain_package('openvox-agent')
              .with_ensure('latest')
              .with_source('/var/cache/openvox-agent_9.0.0.alpha2-1+ubuntu24.04.deb')
              .with_provider('dpkg')
              .that_requires('File[/var/cache/openvox-agent_9.0.0.alpha2-1+ubuntu24.04.deb]')
          }
        end
      end
    end
  end
end
