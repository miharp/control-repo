# frozen_string_literal: true

begin
  gem 'logger', '~> 1.7'
rescue Gem::LoadError
  # Fall back to the default logger if this version isn't available.
end
require 'logger'

require 'rspec-puppet'
require 'rspec-puppet-facts'
include RspecPuppetFacts

RSpec.configure do |c|
  fixture_path = File.expand_path('fixtures', __dir__)
  c.module_path = File.join(fixture_path, 'modules')

  c.default_facts = {
    os: {
      family: 'RedHat',
      release: {
        major: '9',
      },
    },
  }
end

