# frozen_string_literal: true

require 'spec_helper'
require 'base64'
require 'fileutils'
require 'openssl'
require 'tmpdir'

# This spec exists to validate that the eyaml backend can be loaded and used by
# rspec-puppet when running inside VoxBox.
#
# IMPORTANT: Do not commit PKCS7 private keys to the repo. This spec generates a
# throwaway keypair and encrypted data at runtime to keep the test end-to-end
# without storing key material in git.

describe 'test_eyaml_lookup', type: :class do
  let(:secret_value) { 'voxbox_test_secret' }
  let(:tmp_root) { Dir.mktmpdir('rspec-eyaml-') }

  after do
    FileUtils.remove_entry(tmp_root) if File.directory?(tmp_root)
  end

  let(:data_dir) { File.join(tmp_root, 'data') }
  let(:keys_dir) { File.join(tmp_root, 'keys') }
  let(:private_key_path) { File.join(keys_dir, 'private_key.pkcs7.pem') }
  let(:public_key_path) { File.join(keys_dir, 'public_key.pkcs7.pem') }
  let(:common_eyaml_path) { File.join(data_dir, 'common.eyaml') }
  let(:hiera_config) { File.join(tmp_root, 'hiera.yaml') }

  before do
    FileUtils.mkdir_p(data_dir)
    FileUtils.mkdir_p(keys_dir)

    rsa_key = OpenSSL::PKey::RSA.new(2048)
    File.write(private_key_path, rsa_key.to_pem)

    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    name = OpenSSL::X509::Name.parse('/CN=eyaml-test')
    cert.subject = name
    cert.issuer = name
    cert.public_key = rsa_key.public_key
    cert.not_before = Time.now
    cert.not_after = Time.now + (3650 * 24 * 60 * 60)
    ext_factory = OpenSSL::X509::ExtensionFactory.new
    ext_factory.subject_certificate = cert
    ext_factory.issuer_certificate = cert
    cert.add_extension(ext_factory.create_extension('basicConstraints', 'CA:TRUE', true))
    cert.add_extension(ext_factory.create_extension('keyUsage', 'keyEncipherment,dataEncipherment,digitalSignature', true))
    cert.sign(rsa_key, OpenSSL::Digest::SHA256.new)
    File.write(public_key_path, cert.to_pem)

    pkcs7 = OpenSSL::PKCS7.encrypt(
      [cert],
      secret_value,
      OpenSSL::Cipher.new('AES-256-CBC'),
      OpenSSL::PKCS7::BINARY,
    )
    enc = Base64.strict_encode64(pkcs7.to_der)
    File.write(
      common_eyaml_path,
      <<~YAML,
        ---
        profile::base::eyaml_secret: >
          ENC[PKCS7,#{enc}]
      YAML
    )

    File.write(
      hiera_config,
      <<~YAML,
        ---
        version: 5

        defaults:
          datadir: "#{data_dir}"

        hierarchy:
          - name: "Eyaml backend"
            lookup_key: eyaml_lookup_key
            paths:
              - "common.eyaml"
            options:
              pkcs7_private_key: "#{private_key_path}"
              pkcs7_public_key: "#{public_key_path}"
      YAML
    )

    Puppet[:hiera_config] = hiera_config
  end

  let(:pre_condition) do
    <<~PUPPET
      class test_eyaml_lookup {
        notify { 'eyaml_lookup_test':
          message => lookup('profile::base::eyaml_secret'),
        }
      }
    PUPPET
  end

  it 'decrypts eyaml data via lookup()' do
    is_expected.to compile
    is_expected.to contain_notify('eyaml_lookup_test').with_message(secret_value)
  end
end
