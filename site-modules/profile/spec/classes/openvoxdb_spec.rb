# frozen_string_literal: true

require 'spec_helper'

describe 'profile::openvoxdb' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it { is_expected.to contain_class('openvoxdb') }
      it { is_expected.to contain_class('openvoxdb::master::config') }
    end
  end
end
