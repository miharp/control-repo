Vagrant.configure("2") do |config|
  # The multi-machine environment is sensitive to puppetserver restarts during
  # master convergence (e.g., when PuppetDB integration is applied). If agents
  # start in parallel, they can hit transient connection-refused errors.
  #
  # Default to sequential bring-up for reliability; override by explicitly
  # setting VAGRANT_NO_PARALLEL=0 when running Vagrant.
  ENV['VAGRANT_NO_PARALLEL'] ||= '1'

  # Set OPENVOX_TEST_REPO=1 to install from the pre-release testing repository
  # instead of the production repository during provisioning.
  openvox_test_repo = ENV['OPENVOX_TEST_REPO'] == '1'
  yum_release_base = openvox_test_repo \
    ? 'https://s3.osuosl.org/openvox-artifacts/repo_test/yum' \
    : 'https://yum.voxpupuli.org'
  apt_release_base = openvox_test_repo \
    ? 'https://s3.osuosl.org/openvox-artifacts/repo_test/apt' \
    : 'https://apt.voxpupuli.org'

  config.vm.box = "bento/centos-stream-9"

  # Master Node: puppet
  config.vm.define "puppet" do |puppet|
    puppet.vm.box = "bento/centos-stream-10"
    puppet.vm.hostname = "puppet.example.com"
    puppet.vm.network "private_network", ip: "192.168.56.10"
    
    puppet.vm.provider "parallels" do |prl|
      prl.memory = 3072
      prl.cpus = 2
    end 

    # Sync control-repo to production environment
    puppet.vm.synced_folder ".", "/etc/puppetlabs/code/environments/production"

    puppet.vm.provision "shell", inline: <<-SHELL
      # Set up /etc/hosts
      echo "192.168.56.10 puppet.example.com puppet" >> /etc/hosts
      echo "192.168.56.11 agent01.example.com agent01" >> /etc/hosts
      echo "192.168.56.12 agent02.example.com agent02" >> /etc/hosts
      echo "192.168.56.13 compiler.example.com compiler" >> /etc/hosts

      # Update all packages
      dnf update -y

      # Tools used by readiness checks
      dnf install -y curl


      # pp_role has to be in the CSR before the certificate is issued: it is an
      # X.509 extension, so it cannot be added to a signed cert afterwards
      # without re-issuing. Anything that authorizes on role -- codavox's
      # publisher, and puppetserver's own auth.conf -- depends on it being here
      # from the first boot.
      install -d -m 0755 /etc/puppetlabs/puppet
      tee /etc/puppetlabs/puppet/csr_attributes.yaml > /dev/null <<'CSRYAML'
---
extension_requests:
  pp_role: openvox_server
CSRYAML

      # Install OpenVox repository
      rpm -Uvh #{yum_release_base}/openvox8-release-el-10.noarch.rpm

      # Install OpenVox Server
      dnf install -y openvox-server

      # Install git (required for r10k if using git sources, and for config_version)
      dnf install -y git

      # Ensure firewalld is running
      systemctl enable --now firewalld

      # Configure Firewall
      firewall-cmd --add-port=8140/tcp --permanent
      firewall-cmd --reload

      # Configure Autosign
      echo "*" > /etc/puppetlabs/puppet/autosign.conf

      # Install r10k
      /opt/puppetlabs/puppet/bin/gem install r10k --no-document

      # Install modules from Puppetfile
      cd /etc/puppetlabs/code/environments/production
      /opt/puppetlabs/puppet/bin/r10k puppetfile install

      # Force clock sync before Puppet CA initialization. Parallels VMs can boot
      # with significant clock skew; if the clock is wrong when puppetserver first
      # starts, it bakes a bad timestamp into the CRL that causes "CRL not yet valid"
      # errors until manually regenerated.
      systemctl stop chronyd 2>/dev/null || true
      chronyd -q 'pool pool.ntp.org iburst' || true
      systemctl start chronyd

      # Eyaml key setup. Keys are stored in keys/ (gitignored, shared folder) so
      # they survive VM destroys. On first provision or fresh clone, generate a
      # new keypair and re-encrypt the canary in data/common.eyaml. Copy keys to
      # a system path owned by puppet so puppetserver can read them.
      EYAML_SHARED_PRIVATE="/etc/puppetlabs/code/environments/production/keys/private_key.pkcs7.pem"
      EYAML_SHARED_PUBLIC="/etc/puppetlabs/code/environments/production/keys/public_key.pkcs7.pem"
      EYAML_DEST="/etc/puppetlabs/eyaml/keys"
      install -d -m 0750 -o puppet -g puppet "$EYAML_DEST"

      if [ ! -f "$EYAML_SHARED_PRIVATE" ]; then
        /opt/puppetlabs/puppet/bin/eyaml createkeys \
          --pkcs7-private-key="$EYAML_SHARED_PRIVATE" \
          --pkcs7-public-key="$EYAML_SHARED_PUBLIC"
        chmod 0644 "$EYAML_SHARED_PRIVATE" "$EYAML_SHARED_PUBLIC"
        CANARY=$(/opt/puppetlabs/puppet/bin/eyaml encrypt -s 'eyaml-canary' \
          --pkcs7-private-key="$EYAML_SHARED_PRIVATE" \
          --pkcs7-public-key="$EYAML_SHARED_PUBLIC" \
          --output=string 2>&1)
        cat > /etc/puppetlabs/code/environments/production/data/common.eyaml <<EYAML
---
# Canary value: validates that hiera-eyaml is functional on every puppet run.
# If catalog compilation fails here, a package upgrade has broken eyaml compatibility.
# See: https://github.com/OpenVoxProject/puppet-runtime/pull/126
# Re-generated by vagrant provisioner when keys/private_key.pkcs7.pem is absent.
profile::base::eyaml_secret: ${CANARY}
EYAML
      fi

      cp "$EYAML_SHARED_PRIVATE" "$EYAML_DEST/private_key.pkcs7.pem"
      cp "$EYAML_SHARED_PUBLIC" "$EYAML_DEST/public_key.pkcs7.pem"
      chown puppet:puppet "$EYAML_DEST/"*.pem
      chmod 0640 "$EYAML_DEST/private_key.pkcs7.pem"
      chmod 0644 "$EYAML_DEST/public_key.pkcs7.pem"

      # Start the service
      systemctl enable --now puppetserver

      # Wait for Puppet Server to be ready
      echo "Waiting for Puppet Server..."
      while ! curl -k https://puppet:8140/status/v1/simple > /dev/null 2>&1; do
        sleep 5
      done

      # Run Puppet Agent twice (2nd run converges after puppetserver restarts)
      /opt/puppetlabs/bin/puppet agent -t || true
      while ! curl -k https://puppet:8140/status/v1/simple > /dev/null 2>&1; do
        sleep 5
      done
      /opt/puppetlabs/bin/puppet agent -t || true

      # Bolt validation support: create a dedicated SSH keypair on the master
      # and publish the public key into the synced control-repo directory so
      # agents can authorize it during their provisioning.
      install -d -m 0700 /root/.ssh
      if [ ! -f /root/.ssh/bolt_ed25519 ]; then
        ssh-keygen -t ed25519 -f /root/.ssh/bolt_ed25519 -N ''
      fi
      install -d -m 0755 /etc/puppetlabs/code/environments/production/.vagrant_bolt_keys
      cp -f /root/.ssh/bolt_ed25519.pub /etc/puppetlabs/code/environments/production/.vagrant_bolt_keys/bolt_ed25519.pub

      # Final stability wait: ensure puppetserver is serving requests after any
      # service refreshes triggered by convergence.
      echo "Waiting for Puppet Server to be stable..."
      ok=0
      while [ "$ok" -lt 3 ]; do
        if curl -k https://puppet:8140/status/v1/simple > /dev/null 2>&1; then
          ok=$((ok+1))
        else
          ok=0
        fi
        sleep 5
      done

      # Smoke-test PuppetDB/OpenVoxDB after convergence
      echo "Waiting for OpenVoxDB (PuppetDB) HTTPS endpoint..."
      for i in $(seq 1 30); do
        if ss -lnt 2>/dev/null | grep -q ':8081'; then
          break
        fi
        sleep 2
      done

      if ! systemctl is-active puppetdb > /dev/null 2>&1; then
        echo "puppetdb service is not active"
        systemctl status puppetdb --no-pager || true
      fi

      curl -sS --cacert /etc/puppetlabs/puppet/ssl/certs/ca.pem \
        --cert /etc/puppetlabs/puppet/ssl/certs/puppet.example.com.pem \
        --key /etc/puppetlabs/puppet/ssl/private_keys/puppet.example.com.pem \
        https://puppet.example.com:8081/pdb/meta/v1/version || true
    SHELL
  end


  # Compiler Node: runs OpenVox Server, but defers the CA to the primary.
  #
  # A compiler compiles catalogs and serves file content; it does not issue
  # certificates. That is what makes it the node codavox exists for -- the
  # publisher on the primary distributes resolved code to compilers, and each
  # compiler answers which exact version it is serving.
  config.vm.define "compiler" do |compiler|
    compiler.vm.box = "bento/centos-stream-10"
    compiler.vm.hostname = "compiler.example.com"
    compiler.vm.network "private_network", ip: "192.168.56.13"

    compiler.vm.provider "parallels" do |prl|
      prl.memory = 3072
      prl.cpus = 2
    end

    compiler.vm.provision "shell", inline: <<-SHELL
      # Set up /etc/hosts
      echo "192.168.56.10 puppet.example.com puppet" >> /etc/hosts
      echo "192.168.56.11 agent01.example.com agent01" >> /etc/hosts
      echo "192.168.56.12 agent02.example.com agent02" >> /etc/hosts
      echo "192.168.56.13 compiler.example.com compiler" >> /etc/hosts

      dnf update -y
      dnf install -y curl git

      # pp_role has to be in the CSR before the certificate is issued: it is an
      # X.509 extension, so it cannot be added to a signed cert afterwards
      # without re-issuing. codavox's publisher authorizes on exactly this --
      # a certificate signed by the CA only proves the peer is some enrolled
      # node, and every agent in the estate clears that bar.
      install -d -m 0755 /etc/puppetlabs/puppet
      tee /etc/puppetlabs/puppet/csr_attributes.yaml > /dev/null <<'CSRYAML'
---
extension_requests:
  pp_role: openvox_compiler
CSRYAML

      rpm -Uvh #{yum_release_base}/openvox8-release-el-10.noarch.rpm
      dnf install -y openvox-server

      # Point at the primary for both catalogs and the CA before enrolling, so
      # the certificate is issued by the primary's CA rather than a second one
      # this node would otherwise stand up for itself.
      /opt/puppetlabs/bin/puppet config set --section main server puppet.example.com
      /opt/puppetlabs/bin/puppet config set --section main ca_server puppet.example.com
      /opt/puppetlabs/bin/puppet config set --section main certname compiler.example.com

      systemctl enable --now firewalld
      firewall-cmd --add-port=8140/tcp --permanent
      firewall-cmd --reload

      # Clock sync before enrolling. A skewed clock at certificate issuance
      # produces "CRL not yet valid" errors that persist until regenerated.
      systemctl stop chronyd 2>/dev/null || true
      chronyd -q 'pool pool.ntp.org iburst' || true
      systemctl start chronyd

      # Wait for the primary's CA to be serving before requesting a certificate.
      echo "Waiting for the primary..."
      ok=0
      while [ "$ok" -lt 3 ]; do
        if curl -k https://puppet:8140/status/v1/simple > /dev/null 2>&1; then
          ok=$((ok+1))
        else
          ok=0
        fi
        sleep 5
      done

      # Enrol. The primary autosigns in this environment, so the signed
      # certificate comes back carrying pp_role from csr_attributes.yaml.
      /opt/puppetlabs/bin/puppet ssl bootstrap --waitforcert 10 || true

      # Serve catalogs with the primary's CA material, and disable this node's
      # own CA service so it never issues a certificate.
      SSLDIR=/etc/puppetlabs/puppet/ssl
      tee /etc/puppetlabs/puppetserver/conf.d/webserver.conf > /dev/null <<HOCON
webserver: {
    access-log-config: /etc/puppetlabs/puppetserver/request-logging.xml
    client-auth: want
    ssl-host: 0.0.0.0
    ssl-port: 8140
    ssl-cert: ${SSLDIR}/certs/compiler.example.com.pem
    ssl-key: ${SSLDIR}/private_keys/compiler.example.com.pem
    ssl-ca-cert: ${SSLDIR}/certs/ca.pem
    ssl-crl-path: ${SSLDIR}/crl.pem
}
HOCON

      ca_cfg=/etc/puppetlabs/puppetserver/services.d/ca.cfg
      sed -i \
        -e 's|^puppetlabs.services.ca.certificate-authority-service/|#puppetlabs.services.ca.certificate-authority-service/|' \
        -e 's|^#puppetlabs.services.ca.certificate-authority-disabled-service/|puppetlabs.services.ca.certificate-authority-disabled-service/|' \
        "$ca_cfg"

      systemctl enable --now puppetserver

      # Development environment: converge once, then leave the agent off and run
      # it by hand, matching the other nodes.
      systemctl stop puppet || true
      /opt/puppetlabs/bin/puppet agent -t --waitforlock 60 || true
      systemctl disable --now puppet || true
    SHELL
  end

  # Agent Node: agent01
  config.vm.define "agent01" do |agent|
    agent.vm.hostname = "agent01.example.com"
    agent.vm.network "private_network", ip: "192.168.56.11"

    agent.vm.provider "parallels" do |prl|
      prl.memory = 1024
    end

    agent.vm.provision "shell", inline: <<-SHELL
      # Set up /etc/hosts
      echo "192.168.56.10 puppet.example.com puppet" >> /etc/hosts
      echo "192.168.56.11 agent01.example.com agent01" >> /etc/hosts
      echo "192.168.56.12 agent02.example.com agent02" >> /etc/hosts
      echo "192.168.56.13 compiler.example.com compiler" >> /etc/hosts

      # Update all packages
      dnf update -y


      # pp_role has to be in the CSR before the certificate is issued: it is an
      # X.509 extension, so it cannot be added to a signed cert afterwards
      # without re-issuing. Anything that authorizes on role -- codavox's
      # publisher, and puppetserver's own auth.conf -- depends on it being here
      # from the first boot.
      install -d -m 0755 /etc/puppetlabs/puppet
      tee /etc/puppetlabs/puppet/csr_attributes.yaml > /dev/null <<'CSRYAML'
---
extension_requests:
  pp_role: openvox_agent
CSRYAML

      # Install OpenVox repository
      rpm -Uvh #{yum_release_base}/openvox8-release-el-9.noarch.rpm

      # Tools used by readiness checks
      dnf install -y curl

      # Install OpenVox Agent
      dnf install -y openvox-agent

      # Bolt validation support: authorize the master's Bolt SSH key.
      while [ ! -f /vagrant/.vagrant_bolt_keys/bolt_ed25519.pub ]; do
        sleep 2
      done
      install -d -m 0700 /home/vagrant/.ssh
      touch /home/vagrant/.ssh/authorized_keys
      chmod 0600 /home/vagrant/.ssh/authorized_keys
      chown -R vagrant:vagrant /home/vagrant/.ssh
      grep -q -F "$(cat /vagrant/.vagrant_bolt_keys/bolt_ed25519.pub)" /home/vagrant/.ssh/authorized_keys || cat /vagrant/.vagrant_bolt_keys/bolt_ed25519.pub >> /home/vagrant/.ssh/authorized_keys

      # Avoid lock races: the puppet service may auto-start and run an agent
      # cycle in the background. Stop it before running our one-shot converge.
      systemctl stop puppet || true

      # Wait for Puppet Master to be ready
      echo "Waiting for Puppet Master..."
      ok=0
      while [ "$ok" -lt 3 ]; do
        if curl -k https://puppet:8140/status/v1/simple > /dev/null 2>&1; then
          ok=$((ok+1))
        else
          ok=0
        fi
        sleep 5
      done

      # Development environment: keep the puppet service disabled and run
      # puppet manually when needed.
      /opt/puppetlabs/bin/puppet agent -t --waitforlock 60 || true
      systemctl disable --now puppet || true
    SHELL
  end

  # Agent Node: agent02 (Ubuntu LTS)
  config.vm.define "agent02" do |agent|
    agent.vm.box = "bento/ubuntu-24.04"
    agent.vm.hostname = "agent02.example.com"
    agent.vm.network "private_network", ip: "192.168.56.12"

    agent.vm.provider "parallels" do |prl|
      prl.memory = 1024
    end

    agent.vm.provision "shell", inline: <<-SHELL
      set -e

      # Set up /etc/hosts
      echo "192.168.56.10 puppet.example.com puppet" | sudo tee -a /etc/hosts > /dev/null
      echo "192.168.56.11 agent01.example.com agent01" | sudo tee -a /etc/hosts > /dev/null
      echo "192.168.56.12 agent02.example.com agent02" | sudo tee -a /etc/hosts > /dev/null
      echo "192.168.56.13 compiler.example.com compiler" | sudo tee -a /etc/hosts > /dev/null

      # Update all packages
      sudo apt-get update -y
      sudo apt-get upgrade -y

      # Install OpenVox repository + agent (Debian/Ubuntu)
      sudo apt-get install -y curl ca-certificates

      # pp_role has to be in the CSR before the certificate is issued: it is an
      # X.509 extension, so it cannot be added to a signed cert afterwards
      # without re-issuing. Anything that authorizes on role -- codavox's
      # publisher, and puppetserver's own auth.conf -- depends on it being here
      # from the first boot.
      sudo install -d -m 0755 /etc/puppetlabs/puppet
      sudo tee /etc/puppetlabs/puppet/csr_attributes.yaml > /dev/null <<'CSRYAML'
---
extension_requests:
  pp_role: openvox_agent
CSRYAML

      curl -fsSL -o /tmp/openvox8-release-ubuntu24.04.deb #{apt_release_base}/openvox8-release-ubuntu24.04.deb
      sudo dpkg -i /tmp/openvox8-release-ubuntu24.04.deb
      sudo apt-get update -y
      sudo apt-get install -y openvox-agent

      # Bolt validation support: authorize the master's Bolt SSH key.
      while [ ! -f /vagrant/.vagrant_bolt_keys/bolt_ed25519.pub ]; do
        sleep 2
      done
      sudo install -d -m 0700 /home/vagrant/.ssh
      sudo touch /home/vagrant/.ssh/authorized_keys
      sudo chmod 0600 /home/vagrant/.ssh/authorized_keys
      sudo chown -R vagrant:vagrant /home/vagrant/.ssh
      grep -q -F "$(cat /vagrant/.vagrant_bolt_keys/bolt_ed25519.pub)" /home/vagrant/.ssh/authorized_keys || cat /vagrant/.vagrant_bolt_keys/bolt_ed25519.pub >> /home/vagrant/.ssh/authorized_keys

      # Avoid lock races: the puppet service may auto-start and run an agent
      # cycle in the background. Stop it before running our one-shot converge.
      sudo systemctl stop puppet || true

      # Wait for Puppet Master to be ready
      echo "Waiting for Puppet Master..."
      ok=0
      while [ "$ok" -lt 3 ]; do
        if curl -k https://puppet:8140/status/v1/simple > /dev/null 2>&1; then
          ok=$((ok+1))
        else
          ok=0
        fi
        sleep 5
      done

      # Development environment: keep the puppet service disabled and run
      # puppet manually when needed.
      sudo /opt/puppetlabs/bin/puppet agent -t --waitforlock 60 || true
      sudo systemctl disable --now puppet || true
    SHELL
  end
end
