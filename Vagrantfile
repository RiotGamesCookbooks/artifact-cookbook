VERSION = ENV["artifact_test_version"] || "1.2.3"
LOCATION = ENV["artifact_test_location"] || "/vagrant/fixtures/artifact_test-#{VERSION}.tgz"

Vagrant.configure("2") do |config|

  config.vm.hostname = "artifact-berkshelf"

  config.berkshelf.enabled = true

  config.vm.box = "Berkshelf-CentOS-6.3-x86_64-minimal"
  config.vm.box_url = "https://dl.dropbox.com/u/31081437/Berkshelf-CentOS-6.3-x86_64-minimal.box"

  config.vm.network :private_network, ip: "192.168.33.10"

  config.vm.provision :chef_solo do |chef|
    chef.json = {
      :artifact_test => {
        :version => VERSION,
        :location => LOCATION
      }
    }

    chef.data_bags_path = "./fixtures/databags/"

    chef.run_list = [
      "recipe[artifact_test::default]"
    ]
  end
end
