# Local eyaml keys

This directory is where you can put a local PKCS7 keypair for `hiera-eyaml`.

The control-repo Hiera config references these paths:

- `keys/private_key.pkcs7.pem`
- `keys/public_key.pkcs7.pem`

These files are intentionally **not** committed; they are ignored via [.gitignore](../.gitignore).

To generate a throwaway keypair for local testing:

1. `openssl genrsa -out keys/private_key.pkcs7.pem 2048`
2. `openssl req -new -x509 -key keys/private_key.pkcs7.pem -out keys/public_key.pkcs7.pem -days 3650 -subj "/CN=eyaml-test"`

Do not reuse these keys for real secrets.
