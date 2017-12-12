VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Development Server
  config.vm.define "saritasa-dev", primary: true do |dev|
	dev.vm.provider :virtualbox do |virtualbox|
      virtualbox.customize ["modifyvm", :id, "--memory", "1024"]
      virtualbox.customize ["modifyvm", :id, "--cpus", "2"]
    end
    
	dev.vm.hostname = "saritasa-dev"
    dev.vm.box = "centos/7"
	#dev.vm.network "forwarded_port", guest: 5000, host: 5000
    dev.vm.network "private_network", ip: "192.168.0.10"
    dev.vm.provision :chef_solo do |chef|
		chef.add_recipe "simplephpapp"
	end
  end

end
