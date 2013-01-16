#
# Cookbook Name:: artifact_test
# Recipe:: artifact_rollback_tests
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# To execute this Chef run, you'll need to define attributes for [:artifact_test][:first_location] and [:artifact_test][:second_location]

group "artifact"
user "artifact" do
  group "artifact"
end

first_artifact_location = node[:artifact_test][:first_location]
first_artifact_version  = "1.0.0"

second_artifact_location = node[:artifact_test][:second_location]
second_artifact_version = "2.0.0"

artifact_deploy "artifact_test" do
  version           first_artifact_version
  artifact_location first_artifact_location
  deploy_to         "/srv/artifact_test"
  owner             "artifact"
  group             "artifact"
  action            :deploy
end

artifact_deploy "artifact_test" do
  version           second_artifact_version
  artifact_location second_artifact_location
  deploy_to         "/srv/artifact_test"
  owner             "artifact"
  group             "artifact"
  action            :deploy
end

ruby_block "make sure get_current_deployed_version library call works and is correct" do
  block do
    Chef::Application.fatal! "get_current_deployed_version is broken or incorrect!" unless Chef::Artifact.get_current_deployed_version("/srv/artifact_test") == "2.0.0"
  end
end

artifact_deploy "artifact_test" do
  version           first_artifact_version
  artifact_location first_artifact_location
  deploy_to         "/srv/artifact_test"
  owner             "artifact"
  group             "artifact"
  action            :deploy
end

ruby_block "make sure get_current_deployed_version library call works and is correct" do
  block do
    Chef::Application.fatal! "get_current_deployed_version is broken or incorrect!" unless Chef::Artifact.get_current_deployed_version("/srv/artifact_test") == "1.0.0"
  end
end

artifact_deploy "artifact_test" do
  version           second_artifact_version
  artifact_location second_artifact_location
  deploy_to         "/srv/artifact_test"
  owner             "artifact"
  group             "artifact"

  restart Proc.new {
    file "/tmp/#{artifact_filename}" do
      owner "artifact"
      group "artifact"
      mode 0755
      content "Test!"
      action :create
    end
    
  }

  action            :deploy
end