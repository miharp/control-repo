# frozen_string_literal: true

require 'spec_helper'

describe 'profile::openvox_server' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { version: '8.12.1' } }

      it { is_expected.to compile.with_all_deps }

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
    end
  end
end
