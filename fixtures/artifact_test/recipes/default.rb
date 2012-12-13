#
# Cookbook Name:: artifact_test
# Recipe:: default
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
  deploy_to "/srv/artifact_test"
  owner "artifact"
  group "artifact"

  action :deploy
end
