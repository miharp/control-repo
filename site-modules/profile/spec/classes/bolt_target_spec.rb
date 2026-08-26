# frozen_string_literal: true

require 'spec_helper'

describe 'profile::bolt_target' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      # profile::base declares the sudo class; sudo::conf needs it.
      let(:pre_condition) { "class { 'sudo': }" }

      context 'without keys and without PuppetDB (rspec-puppet, Onceover)' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_class('openvox_gui::bolt_target') }
        it { is_expected.not_to contain_sudo__conf('bolt') }
      end

      context 'with keys from hiera' do
        let(:params) { { authorized_keys: ['ssh-ed25519 AAAAC3test openvox-gui-bolt'] } }

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_class('openvox_gui::bolt_target')
            .with_authorized_keys(['ssh-ed25519 AAAAC3test openvox-gui-bolt'])
        }

        it { is_expected.to contain_user('bolt').with_home('/home/bolt') }
        it { is_expected.to contain_file('/home/bolt/.ssh/authorized_keys').with_content(%r{^ssh-ed25519 AAAAC3test openvox-gui-bolt$}) }

        it 'grants the bolt user passwordless sudo through saz/sudo so the base purge keeps it' do
          expect(subject).to contain_sudo__conf('bolt').with_content('bolt ALL=(ALL) NOPASSWD: ALL')
        end
      end
    end
  end
end
