#
# Cookbook Name:: artifact_test
# Recipe:: nexus_package
#
# Author:: Aaron Feng (<aaron.feng@riotgames.com>)
#
# Copyright 2013, Riot Games
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

group "artifact"
user "artifacts"

nexus_configuration = Chef::Artifact::NexusConfiguration.new(
  node[:artifact_test][:other_nexus][:url], node[:artifact_test][:other_nexus][:repository]
)

after_download_prc = Proc.new {
  Chef::Log.info "*** after download proc was executed! ***"
}

# make sure it works without after_download proc
artifact_package "without after download proc" do
  location node[:artifact_test][:other_nexus][:location]
  nexus_configuration nexus_configuration
  owner "artifacts"
  group "artifact"
  action :install
end

rpm_package node[:artifact_test][:other_nexus][:app_name] do
  action :remove
end

file "/var/chef/cache/artifact_packages/#{node[:artifact_test][:other_nexus][:rpm_name]}" do
  action :delete
end

# make sure it works with after_download proc
artifact_package "with after download proc" do
  nexus_configuration nexus_configuration
  after_download after_download_prc
  location node[:artifact_test][:other_nexus][:location]
  owner "artifacts"
  group "artifact"
  action :install
end

