Vagrant.configure("2") do |config|
  # The multi-machine environment is sensitive to puppetserver restarts during
  # master convergence (e.g., when PuppetDB integration is applied). If agents
  # start in parallel, they can hit transient connection-refused errors.
  #
  # Default to sequential bring-up for reliability; override by explicitly
  # setting VAGRANT_NO_PARALLEL=0 when running Vagrant.
  ENV['VAGRANT_NO_PARALLEL'] ||= '1'

  config.vm.box = "bento/centos-stream-9"

  # Master Node: puppet
  config.vm.define "puppet" do |puppet|
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

      # Update all packages
      dnf update -y

      # Tools used by readiness checks
      dnf install -y curl

      # Install OpenVox repository
      rpm -Uvh https://yum.voxpupuli.org/openvox8-release-el-9.noarch.rpm

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

      # Update all packages
      dnf update -y

      # Install OpenVox repository
      rpm -Uvh https://yum.voxpupuli.org/openvox8-release-el-9.noarch.rpm

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

      # Update all packages
      sudo apt-get update -y
      sudo apt-get upgrade -y

      # Install OpenVox repository + agent (Debian/Ubuntu)
      sudo apt-get install -y curl ca-certificates
      curl -fsSL -o /tmp/openvox8-release-ubuntu24.04.deb https://apt.voxpupuli.org/openvox8-release-ubuntu24.04.deb
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
