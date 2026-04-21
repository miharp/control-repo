# frozen_string_literal: true

require 'spec_helper'

describe 'profile::base' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { release: 8 } }
      let(:pre_condition) do
        "class { 'profile::openvox_agent': version => '8.24.2' }"
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('chrony') }
      it { is_expected.to contain_class('firewall') }
      it { is_expected.to contain_class('profile::openvox_agent') }
      it { is_expected.to contain_class('sudo') }

      it {
        is_expected.to contain_firewall('100 allow puppet')
          .with_dport(8140)
          .with_proto('tcp')
          .with_jump('ACCEPT')
      }

      it {
        is_expected.to contain_sudo__conf('mharp')
          .with_content('mharp ALL=(ALL) NOPASSWD: ALL')
      }

      it {
        is_expected.to contain_sudo__conf('vagrant')
          .with_content('vagrant ALL=(ALL) NOPASSWD: ALL')
      }

      if os_facts[:os]['family'] == 'RedHat'
        it {
          is_expected.to contain_package('openvox8-release')
            .with_ensure('present')
            .with_provider('rpm')
        }

        it {
          is_expected.to contain_yumrepo('openvox8')
            .with_ensure('present')
            .with_metadata_expire('300')
            .that_requires('Package[openvox8-release]')
        }
      end
    end
  end
end
