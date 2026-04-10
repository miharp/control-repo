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

  # rspec-puppet tries to create the module-under-test symlink for each
  # example group via File.symlink, which raises EEXIST if the link already
  # exists. We must ensure it is absent before rspec-puppet's hook runs.
  #
  # In parallel_spec, multiple processes share the same fixture path. A naive
  # rm_rf creates a window where one process deletes the symlink while another
  # is actively compiling a catalog, causing "Could not find declared class".
  #
  # Fix: atomically replace the symlink using a temp name + File.rename, which
  # is POSIX-atomic. rspec-puppet's subsequent File.symlink gets EEXIST, which
  # is rescued below, and the link is already correct, so tests proceed safely.
  c.prepend_before(:context) do
    module_link = File.join(fixture_path, 'modules', 'profile')
    source_dir  = File.expand_path('../..', fixture_path)
    tmp         = "#{module_link}.tmp.#{Process.pid}"
    FileUtils.rm_f(tmp)
    File.symlink(source_dir, tmp)
    File.rename(tmp, module_link)
  rescue StandardError
    # If rename loses a race with another worker, the link already exists
    # and points correctly — nothing to do.
    FileUtils.rm_f(tmp) rescue nil # rubocop:disable Style/RescueModifier
  end

  # Suppress the EEXIST error from rspec-puppet's own symlink attempt, which
  # fires after our hook has already created the link atomically.
  original_symlink = File.method(:symlink)
  File.define_singleton_method(:symlink) do |src, dst|
    original_symlink.call(src, dst)
  rescue Errno::EEXIST
    0 # match File.symlink return value
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

