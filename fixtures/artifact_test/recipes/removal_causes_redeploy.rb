# Cookbook Name:: artifact_test
# Recipe:: removal_causes_redeploy
#
# Copyright 2012, YOUR_COMPANY_NAME
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

  action :deploy
end

execute "delete the entire artifact release directory" do
  command "rm -rf /srv/artifact_test/releases/#{node[:artifact_test][:version]}"
  action :run
end

artifact_deploy "artifact_test" do
  version node[:artifact_test][:version]
  artifact_location node[:artifact_test][:location]
  artifact_checksum node[:artifact_test][:checksum]
  deploy_to "/srv/artifact_test"
  owner "artifact"
  group "artifact"

  action :deploy
end

ruby_block "make sure files actually exist in the installed artifact directory" do
  block do
    current_version = Chef::Artifact.get_current_deployed_version('/srv/artifact_test')
    entries_size = Dir.entries("/srv/artifact_test/releases/#{current_version}").size
    Chef::Application.fatal! "no files in installed artifact directory!" unless entries_size > 2
  end
end

# This might be slightly hacky depending on the artifact being installed
files = []
ruby_block "delete a file from the installed directory" do
  block do
    current_version = Chef::Artifact.get_current_deployed_version('/srv/artifact_test')
    files = Dir["/srv/artifact_test/releases/#{current_version}/**"].sort
    `rm -rf #{files.first}`
  end
end

artifact_deploy "artifact_test" do
  version node[:artifact_test][:version]
  artifact_location node[:artifact_test][:location]
  artifact_checksum node[:artifact_test][:checksum]
  deploy_to "/srv/artifact_test"
  owner "artifact"
  group "artifact"

  action :deploy
end

ruby_block "make sure that the deleted file is back" do
  block do
    Chef::Application.fatal! "#{files.first} was not re-extracted!" unless ::File.exists?(files.first)
  end
end