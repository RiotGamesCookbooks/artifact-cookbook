#
# Cookbook Name:: artifact_test
# Recipe:: windows
#
# Copyright 2013, Riot Games
#
# All rights reserved - Do Not Redistribute
#
artifact_deploy "artifact_test" do
  version node[:artifact_test][:version]
  artifact_location node[:artifact_test][:location]
  artifact_checksum node[:artifact_test][:checksum]
  deploy_to node[:artifact_test][:deploy_to]
  owner "artifact"
  group "artifact"

  action :deploy
end