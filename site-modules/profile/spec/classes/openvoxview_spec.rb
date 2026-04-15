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
      }
    end
  end
end
