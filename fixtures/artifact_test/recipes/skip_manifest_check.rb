#
# Cookbook Name:: artifact_test
# Recipe:: skip_manifest_check
#
# Copyright 2012, Riot Games
#
# All rights reserved - Do Not Redistribute
#

group "artifact"
user "artifacts"

artifact_deploy "artifact_test" do
  version node[:artifact_test][:version]
  artifact_location node[:artifact_test][:location]
  artifact_checksum node[:artifact_test][:checksum]
  deploy_to node[:artifact_test][:deploy_to]
  owner "artifacts"
  group "artifact"
  skip_manifest_check true
  action :deploy
end

ruby_block "make sure manifest.yaml does not exist" do
  block do
    manifest_file = ::File.join(node[:artifact_test][:deploy_to], "current", "manifest.yaml")
    Chef::Application.fatal! "Manifest file exists!" if ::File.exists?(manifest_file)
  end
end