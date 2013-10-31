VERSION              = ENV["artifact_test_version"]              || "1.2.3"
LOCATION             = ENV["artifact_test_location"]             || "/vagrant/fixtures/artifact_test-#{VERSION}.tgz"
OTHER_NEXUS_URL      = ENV["artifact_test_other_nexus_url"]      || "https://maven-us.nuxeo.org/nexus"
OTHER_NEXUS_REPO     = ENV["artifact_test_other_nexus_repo"]     || "central"
OTHER_NEXUS_LOCATION = ENV["artifact_test_other_nexus_location"] || "org.mortbay.jetty.dist:jetty-rpm:rpm:8.1.13.v20130916"
OTHER_NEXUS_APP_NAME = ENV["artifact_test_other_nexus_app_name"] || "jetty-hightide-server"
OTHER_NEXUS_RPM_NAME = ENV["artifact_test_other_nexus_rpm_name"] || "jetty-rpm-8.1.13.v20130916.rpm"

Vagrant.configure("2") do |config|

  config.vm.hostname = "artifact-berkshelf"

  config.berkshelf.enabled = true

  config.vm.box = "Berkshelf-CentOS-6.3-x86_64-minimal"
  config.vm.box_url = "https://dl.dropbox.com/u/31081437/Berkshelf-CentOS-6.3-x86_64-minimal.box"

  config.vm.network :private_network, ip: "192.168.33.10"

  config.vm.provision :chef_solo do |chef|
    chef.json = {
      :artifact_test => {
        :other_nexus => {
          :url        => OTHER_NEXUS_URL,
          :repository => OTHER_NEXUS_REPO,
          :app_name   => OTHER_NEXUS_APP_NAME,
          :location   => OTHER_NEXUS_LOCATION,
          :rpm_name   => OTHER_NEXUS_RPM_NAME
        },
        :version => VERSION,
        :location => LOCATION
      }
    }

    chef.data_bags_path = "./fixtures/databags/"

    chef.run_list = [
      "recipe[artifact_test::default]",
      "recipe[artifact_test::nexus_package]",
      "recipe[artifact_test::nexus_anon]"
    ]
  end
end
