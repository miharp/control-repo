# frozen_string_literal: true

require 'spec_helper'

describe 'profile::puppet_run_scheduler' do
  # The profile is only used on macOS, which is not in this module's
  # metadata. facterdb's only Darwin set is Darwin 20; the class branches on
  # the OS family alone.
  on_supported_os(supported_os: [{ 'operatingsystem' => 'Darwin' }]).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('puppet_run_scheduler').with_run_interval('30m') }

      it {
        is_expected.to contain_cron('puppet-run-scheduler')
          .with_user('root')
          .with_command(%r{^/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize })
          .that_comes_before('Service[puppet]')
      }

      it 'gives the cron job a UTF-8 locale so Facter can read system_profiler output' do
        is_expected.to contain_cron('puppet-run-scheduler').with_environment(['LANG=en_US.UTF-8'])
      end

      it { is_expected.to contain_service('puppet').with_ensure('stopped').with_enable(false) }

      context 'with run_interval => 1h' do
        let(:params) { { run_interval: '1h' } }

        it 'runs once in every hour' do
          cron = catalogue.resource('Cron', 'puppet-run-scheduler')
          expect(Array(cron[:minute]).size).to eq(1)
          expect(Array(cron[:hour])).to eq((0..23).to_a)
        end
      end
    end
  end
end
