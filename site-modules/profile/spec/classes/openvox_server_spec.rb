# frozen_string_literal: true

require 'spec_helper'

describe 'profile::openvox_server' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { version: '8.12.1' } }

      it { is_expected.to compile.with_all_deps }

      context 'with the agent package managed in the same catalog' do
        let(:pre_condition) { "package { 'openvox-agent': ensure => '9.0.0' }" }

        if os_facts[:os]['family'] == 'RedHat'
          it 'lets dnf move the server (and its agent dependency) first' do
            is_expected.to contain_package('openvox-server')
              .that_comes_before('Package[openvox-agent]')
          end
        end

        context 'with source URL (rpm resolves no dependencies)' do
          let(:params) do
            {
              version: '9.0.0~rc1-1.el10',
              source: 'https://s3.osuosl.org/openvox-artifacts/openvox-server/9.0.0~rc1/openvox-server-9.0.0~rc1-1.el10.noarch.rpm',
            }
          end

          it {
            is_expected.to contain_package('openvox-agent')
              .that_comes_before('Package[openvox-server]')
          }
        end
      end

      if os_facts[:os]['family'] == 'RedHat'
        it {
          is_expected.to contain_package('openvox-server')
            .with_ensure("8.12.1-1.el#{os_facts[:os]['release']['major']}")
        }
      else
        it {
          is_expected.to contain_package('openvox-server')
            .with_ensure('8.12.1')
        }
      end

      context 'with source URL (pre-release install)' do
        let(:params) do
          {
            version: '8.13.0-0.1SNAPSHOT.2026.04.24T1621.el10',
            source: 'https://artifacts.voxpupuli.org/openvox-server/8.13.0-0.1SNAPSHOT.2026.04.24T1621/openvox-server-8.13.0-0.1SNAPSHOT.2026.04.24T1621.el10.noarch.rpm',
          }
        end

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_package('openvox-server')
            .with_ensure('8.13.0-0.1SNAPSHOT.2026.04.24T1621.el10')
            .with_source('https://artifacts.voxpupuli.org/openvox-server/8.13.0-0.1SNAPSHOT.2026.04.24T1621/openvox-server-8.13.0-0.1SNAPSHOT.2026.04.24T1621.el10.noarch.rpm')
            .with_provider('rpm')
        }

        context 'with java_package' do
          let(:params) { super().merge(java_package: 'java-25-openjdk-headless') }

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_package('java-25-openjdk-headless')
              .that_comes_before('Package[openvox-server]')
          }
        end
      end
    end
  end
end
