# frozen_string_literal: true

require 'spec_helper'

describe 'profile::static_catalogs' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('profile::static_catalogs') }

        # Scripts directory
        it {
          is_expected.to contain_file('/opt/puppetlabs/server/data/puppetserver/scripts')
            .with_ensure('directory')
            .with_owner('puppet')
            .with_group('puppet')
            .with_mode('0755')
        }

        # code_id script
        it {
          is_expected.to contain_file('/opt/puppetlabs/server/data/puppetserver/scripts/code_id.sh')
            .with_ensure('file')
            .with_owner('puppet')
            .with_group('puppet')
            .with_mode('0755')
            .with_source('puppet:///modules/profile/static_catalogs/code_id.sh')
        }

        # code_content script
        it {
          is_expected.to contain_file('/opt/puppetlabs/server/data/puppetserver/scripts/code_content.sh')
            .with_ensure('file')
            .with_owner('puppet')
            .with_group('puppet')
            .with_mode('0755')
            .with_source('puppet:///modules/profile/static_catalogs/code_content.sh')
        }

        # puppet.conf settings
        it {
          is_expected.to contain_ini_setting('static_catalogs')
            .with_ensure('present')
            .with_path('/etc/puppetlabs/puppet/puppet.conf')
            .with_section('server')
            .with_setting('static_catalogs')
            .with_value(true)
        }

        # code_id_command and code_content_command are not Puppet settings;
        # Puppet Server reads them from versioned-code.conf, not puppet.conf.
        # The profile purges them so an old, inert pair does not linger.
        it {
          is_expected.to contain_ini_setting('purge inert code_id_command')
            .with_ensure('absent')
            .with_path('/etc/puppetlabs/puppet/puppet.conf')
            .with_section('server')
            .with_setting('code_id_command')
        }

        it {
          is_expected.to contain_ini_setting('purge inert code_content_command')
            .with_ensure('absent')
            .with_path('/etc/puppetlabs/puppet/puppet.conf')
            .with_section('server')
            .with_setting('code_content_command')
        }

        # Puppetserver versioned-code.conf (HOCON format)
        it {
          is_expected.to contain_file('/etc/puppetlabs/puppetserver/conf.d/versioned-code.conf')
            .with_ensure('file')
            .with_owner('root')
            .with_group('root')
            .with_mode('0644')
            .that_notifies('Service[puppetserver]')
        }

        # Service notification
        it {
          is_expected.to contain_ini_setting('static_catalogs')
            .that_notifies('Service[puppetserver]')
        }

        it {
          is_expected.to contain_service('puppetserver')
            .with_ensure('running')
            .with_enable(true)
        }
      end

      context 'with enabled => false' do
        let(:params) { { enabled: false } }

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_ini_setting('static_catalogs')
            .with_ensure('absent')
        }

        # The purge is unconditional, so it stays absent here too.
        it {
          is_expected.to contain_ini_setting('purge inert code_id_command')
            .with_ensure('absent')
        }

        it {
          is_expected.to contain_ini_setting('purge inert code_content_command')
            .with_ensure('absent')
        }

        it {
          is_expected.to contain_file('/etc/puppetlabs/puppetserver/conf.d/versioned-code.conf')
            .with_ensure('absent')
        }
      end

      context 'with custom scripts_dir' do
        let(:params) { { scripts_dir: '/opt/custom/scripts' } }

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_file('/opt/custom/scripts')
            .with_ensure('directory')
        }

        it {
          is_expected.to contain_file('/opt/custom/scripts/code_id.sh')
            .with_ensure('file')
        }

        # scripts_dir drives the versioned-code.conf command paths, which is
        # what actually points Puppet Server at the scripts.
        it {
          is_expected.to contain_file('/etc/puppetlabs/puppetserver/conf.d/versioned-code.conf')
            .with_content(%r{/opt/custom/scripts/code_id\.sh})
            .with_content(%r{/opt/custom/scripts/code_content\.sh})
        }
      end
    end
  end
end
