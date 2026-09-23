# frozen_string_literal: true

require 'spec_helper'

describe 'profile::openvox_gui' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { version: '3.10.6', admin_password: 'test-password' } }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_class('openvox_gui')
          .with_version('3.10.6')
          .with_admin_password(sensitive('test-password'))
          .with_app_port(4567)
      }

      it {
        is_expected.to contain_vcsrepo('/opt/openvox-gui-src')
          .with_source('https://github.com/cvquesty/openvox-gui.git')
          .with_revision('v3.10.6')
      }

      it { is_expected.to contain_service('openvox-gui').with_ensure('running') }

      it {
        is_expected.to contain_firewall('200 allow openvox-gui port 4567')
          .with_dport(4567)
          .with_proto('tcp')
          .with_jump('ACCEPT')
      }

      it 'leaves the Bolt inventory to the GUI, which generates its own from 3.14.0' do
        expect(subject).not_to contain_file('/etc/puppetlabs/bolt/inventory.yaml')
      end

      it 'has the module install the openvox_enc inventory plugin the upstream installer forgets' do
        expect(subject).to contain_exec('openvox_gui install openvox_enc bolt plugin')
      end

      context 'with a custom port' do
        let(:params) { super().merge(app_port: 8443) }

        it { is_expected.to contain_class('openvox_gui').with_app_port(8443) }
        it { is_expected.to contain_firewall('200 allow openvox-gui port 8443').with_dport(8443) }
      end
    end
  end
end
