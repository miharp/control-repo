# frozen_string_literal: true

require 'spec_helper'

describe 'profile::openvox_agent' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { version: '1.0.0' } }

      it { is_expected.to compile }
    end
  end
end
