source 'https://rubygems.org'

# Control-repo-wide testing. Onceover compiles every role against representative
# node factsets (see spec/onceover.yaml), complementing the per-module
# rspec-puppet suite in site-modules/profile.
#
# Run from the control-repo root:
#   bundle install
#   bundle exec onceover run spec
group :test do
  # Pin Puppet to the same major the profile module targets (>= 8 < 9).
  gem 'puppet', ENV.fetch('PUPPET_GEM_VERSION', '~> 8.0'), require: false

  gem 'onceover', '~> 5.0', require: false

  # hiera.yaml uses the eyaml backend; rspec-puppet loads the encryptor during
  # compilation. Throwaway keys are generated at test time (see spec/spec_helper.rb).
  gem 'hiera-eyaml', require: false
end
