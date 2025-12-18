Vagrant.configure("2") do |config|
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

      # Install OpenVox repository
      rpm -Uvh https://yum.voxpupuli.org/openvox8-release-el-9.noarch.rpm

      # Install OpenVox Server
      dnf install -y openvox-server

      # Configure Firewall
      firewall-cmd --add-port=8140/tcp --permanent
      firewall-cmd --reload

      # Configure Autosign
      echo "*" > /etc/puppetlabs/puppet/autosign.conf

      # Install r10k
      /opt/puppetlabs/puppet/bin/gem install r10k

      # Install modules from Puppetfile
      cd /etc/puppetlabs/code/environments/production
      /opt/puppetlabs/puppet/bin/r10k puppetfile install

      # Start the service
      systemctl enable --now puppetserver

      # Run Puppet Agent
      /opt/puppetlabs/bin/puppet agent -t || true
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

      # Install OpenVox repository
      rpm -Uvh https://yum.voxpupuli.org/openvox8-release-el-9.noarch.rpm

      # Install OpenVox Agent
      dnf install -y openvox-agent

      # Start the service (agent service is 'puppet')
      systemctl enable --now puppet

      # Run Puppet Agent
      /opt/puppetlabs/bin/puppet agent -t || true
    SHELL
  end
end
