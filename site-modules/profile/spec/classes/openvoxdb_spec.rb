# frozen_string_literal: true

require 'spec_helper'

describe 'profile::openvoxdb' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it { is_expected.to contain_class('openvoxdb') }
      it { is_expected.to contain_class('openvoxdb::master::config') }

      context 'with pre-release source URLs' do
        let(:params) do
          {
            package_version: '8.13.0-0.1SNAPSHOT.2026.04.24T1629.el10',
            package_source: 'https://artifacts.voxpupuli.org/openvoxdb/8.13.0-0.1SNAPSHOT.2026.04.24T1629/openvoxdb-8.13.0-0.1SNAPSHOT.2026.04.24T1629.el10.noarch.rpm',
            termini_source: 'https://artifacts.voxpupuli.org/openvoxdb/8.13.0-0.1SNAPSHOT.2026.04.24T1629/openvoxdb-termini-8.13.0-0.1SNAPSHOT.2026.04.24T1629.el10.noarch.rpm',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_package('openvoxdb')
            .with_ensure('8.13.0-0.1SNAPSHOT.2026.04.24T1629.el10')
            .with_source('https://artifacts.voxpupuli.org/openvoxdb/8.13.0-0.1SNAPSHOT.2026.04.24T1629/openvoxdb-8.13.0-0.1SNAPSHOT.2026.04.24T1629.el10.noarch.rpm')
            .with_provider('rpm')
        }

        it {
          is_expected.to contain_package('openvoxdb-termini')
            .with_ensure('8.13.0-0.1SNAPSHOT.2026.04.24T1629.el10')
            .with_source('https://artifacts.voxpupuli.org/openvoxdb/8.13.0-0.1SNAPSHOT.2026.04.24T1629/openvoxdb-termini-8.13.0-0.1SNAPSHOT.2026.04.24T1629.el10.noarch.rpm')
            .with_provider('rpm')
        }
      end

      context 'with package_version only (repo pin)' do
        let(:params) do
          { package_version: '9.0.0~beta1-1.el10' }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_package('openvoxdb')
            .with_ensure('9.0.0~beta1-1.el10')
            .without_source
        }

        it {
          is_expected.to contain_package('openvoxdb-termini')
            .with_ensure('9.0.0~beta1-1.el10')
            .without_source
        }
      end
    end
  end
end
