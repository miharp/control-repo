# frozen_string_literal: true

require 'spec_helper'

describe 'profile::base' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { release: 8, eyaml_secret: 'test_canary_value' } }
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
            .with_baseurl("https://yum.voxpupuli.org/openvox8/el/#{os_facts[:os]['release']['major']}/$basearch/")
            .with_metadata_expire('300')
            .that_requires('Package[openvox8-release]')
        }
      elsif os_facts[:os]['name'] == 'Ubuntu'
        it { is_expected.to contain_exec('openvox8-apt-key') }
        it {
          is_expected.to contain_file('/etc/apt/sources.list.d/openvox8-release.list')
            .with_ensure('absent')
        }
        it {
          is_expected.to contain_apt__source('openvox8')
            .with_location('https://apt.voxpupuli.org/')
            .with_release("ubuntu#{os_facts[:os]['release']['full']}")
            .with_repos('openvox8')
            .with_keyring('/etc/apt/keyrings/openvox-keyring.gpg')
        }
      end
    end
  end
end
