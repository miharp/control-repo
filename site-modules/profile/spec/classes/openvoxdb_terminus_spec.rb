# frozen_string_literal: true

require 'spec_helper'

describe 'profile::openvoxdb_terminus' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
      it { is_expected.not_to contain_class('openvoxdb') }
      it { is_expected.to contain_package('openvoxdb-termini').with_ensure('present') }

      it {
        is_expected.to contain_class('openvoxdb::master::config')
          .with_puppetdb_server('puppet.example.com')
          .with_puppetdb_port(8081)
          .with_manage_report_processor(true)
          .with_enable_reports(true)
      }

      context 'with another OpenVoxDB host and a pinned terminus version' do
        let(:params) { { server: 'db.example.com', port: 8082, package_version: '8.17.0-1.el10' } }

        it { is_expected.to compile }
        it {
          is_expected.to contain_class('openvoxdb::master::config').with_puppetdb_server('db.example.com').with_puppetdb_port(8082)
        }
        it { is_expected.to contain_package('openvoxdb-termini').with_ensure('8.17.0-1.el10') }
      end
    end
  end
end
