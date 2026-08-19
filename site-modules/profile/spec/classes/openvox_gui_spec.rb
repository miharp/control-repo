# frozen_string_literal: true

require 'spec_helper'

describe 'profile::openvox_gui' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { version: '3.10.6', admin_password: 'test-password' } }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_vcsrepo('/opt/openvox-gui-src')
          .with_source('https://github.com/cvquesty/openvox-gui.git')
          .with_revision('v3.10.6')
      }

      it {
        is_expected.to contain_exec('build openvox-gui frontend')
          .with_unless(%r{cmp -s /opt/openvox-gui-src/VERSION /opt/openvox-gui-src/frontend/.built-version})
      }

      it {
        is_expected.to contain_file('/opt/openvox-gui-src/install.conf')
          .with_mode('0600')
          .with_content(%r{^APP_PORT=4567$})
          .with_content(%r{^ADMIN_PASSWORD=test-password$})
          .with_content(%r{^BUILD_FRONTEND=false$})
          .with_content(%r{^CONFIGURE_ENC=false$})
          .with_content(%r{^CONFIGURE_FIREWALL=false$})
          .with_content(%r{^SSL_ENABLED=true$})
      }

      it {
        is_expected.to contain_exec('install openvox-gui')
          .with_command('/bin/bash install.sh -c install.conf')
          .with_cwd('/opt/openvox-gui-src')
      }

      it {
        is_expected.to contain_service('openvox-gui')
          .with_ensure('running')
          .with_enable(true)
      }

      it {
        is_expected.to contain_firewall('200 allow openvox-gui port 4567')
          .with_dport(4567)
          .with_proto('tcp')
          .with_jump('ACCEPT')
      }

      context 'with a custom port' do
        let(:params) { super().merge(app_port: 8443) }

        it { is_expected.to contain_firewall('200 allow openvox-gui port 8443').with_dport(8443) }
        it { is_expected.to contain_file('/opt/openvox-gui-src/install.conf').with_content(%r{^APP_PORT=8443$}) }
      end
    end
  end
end
