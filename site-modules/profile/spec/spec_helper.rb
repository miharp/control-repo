# frozen_string_literal: true

require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
include RspecPuppetFacts

RSpec.configure do |c|
  c.default_facts = {
    os: {
      family: 'RedHat',
      release: {
        major: '9',
      },
    },
  }
end

