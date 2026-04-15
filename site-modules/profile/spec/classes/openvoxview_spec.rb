# frozen_string_literal: true

require 'spec_helper'

describe 'profile::openvoxview' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { version: '0.1.18' } }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_class('openvoxview')
          .with_version('0.1.18')
          .with_listen_address('0.0.0.0')
          .with_listen_port(5000)
      }

      it {
        is_expected.to contain_firewall('100 allow openvoxview')
          .with_dport(5000)
          .with_proto('tcp')
          .with_jump('ACCEPT')
      }
    end
  end
end
