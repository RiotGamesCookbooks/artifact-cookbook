#
# Cookbook Name:: artifact_test
# Recipe:: pre_seed_tests
#
# Copyright 2012, Riot Games
#
# All rights reserved - Do Not Redistribute
#

group "artifact"
user "artifact" do
  group "artifact"
end

artifact_deploy "artifact_test" do
  version node[:artifact_test][:version]
  artifact_location node[:artifact_test][:location]
  artifact_checksum node[:artifact_test][:checksum]
  deploy_to "/srv/artifact_test"
  owner "artifact"
  group "artifact"

  action :pre_seed
end

ruby_block "make sure pre_seed worked" do
  block do
    Chef::Application.fatal! "pre_seed failed!" unless ::File.exists?(::File.join("/srv/artifact_test", "releases", node[:artifact_test][:version]))
  end
end