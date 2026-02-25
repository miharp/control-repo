# frozen_string_literal: true

begin
  gem 'logger', '~> 1.7'
rescue Gem::LoadError
  # Fall back to the default logger if this version isn't available.
end
require 'logger'
require 'fileutils'

require 'rspec-puppet'
require 'rspec-puppet-facts'
include RspecPuppetFacts

RSpec.configure do |c|
  fixture_path = File.expand_path('fixtures', __dir__)
  c.fixture_path = fixture_path if c.respond_to?(:fixture_path=)
  c.module_path = File.join(fixture_path, 'modules')

  # puppet_fixtures (spec_prep) creates spec/fixtures/modules/profile as a
  # symlink to the literal string '#{source_dir}' because YAML doesn't do Ruby
  # interpolation.  rspec-puppet 5.0 then fails with Errno::EEXIST when it
  # tries to recreate the symlink pointing to the real CWD (link_to_source?
  # returns false since the targets don't match).
  #
  # Fix: atomically replace the symlink with the correct target before
  # rspec-puppet's before(:context) hook runs.  Using rename(2) (POSIX-atomic)
  # means the symlink is never absent, which prevents the parallel_spec race
  # condition that the previous rm_rf approach caused.
  c.prepend_before(:context) do
    module_link = File.join(fixture_path, 'modules', 'profile')
    tmp = "#{module_link}.#{Process.pid}"
    File.symlink(File.expand_path('.'), tmp)
    File.rename(tmp, module_link)
  rescue SystemCallError
    FileUtils.rm_f(tmp) rescue nil # rubocop:disable Style/RescueModifier
  end

  c.default_facts = {
    os: {
      family: 'RedHat',
      release: {
        major: '9',
      },
    },
  }
end

