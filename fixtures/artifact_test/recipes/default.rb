#
# Cookbook Name:: artifact_test
# Recipe:: default
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
  owner "artifact"
  group "artifact"

  action :deploy
end