#
# Cookbook Name:: artifact_test
# Recipe:: nexus_anon
#
# Author:: Kyle Allan (<kallan@riotgames.com>)
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

location_parts    = node[:artifact_test][:other_nexus][:location].split(":")
version  = location_parts[-1]
type     = location_parts[-2]
# notice: replacing the extension and adding classifier
location = node[:artifact_test][:other_nexus][:location].gsub(":#{type}:", ":jar:sources:")
deploy_to         = "/srv/" + node[:artifact_test][:other_nexus][:app_name]

artifact_deploy deploy_to do
  after_download Proc.new { Chef::Log.info "*** artifact_deploy after_download was called ***" }
  version version
  artifact_location location
  nexus_configuration nexus_configuration
  deploy_to deploy_to
  owner "artifacts"
  group "artifact"
  action :deploy
end
