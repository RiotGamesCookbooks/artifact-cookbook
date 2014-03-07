#
# Cookbook Name:: artifact
# Provider:: package
#
# Author:: Michael Ivey (<michael.ivey@riotgames.com>)
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

attr_reader :nexus_configuration_object
attr_reader :extension
attr_reader :file_name

def load_current_resource
  if Chef::Artifact.from_nexus?(new_resource.location)
    chef_gem "nexus_cli" do
      version "4.0.2"
    end
    require 'nexus_cli'
    artifact = NexusCli::Artifact.new(new_resource.location)
    @nexus_configuration_object = new_resource.nexus_configuration
    @extension = artifact.extension
    @file_name = artifact.file_name
  else
    sha = Digest::SHA1.hexdigest new_resource.location
    @extension = new_resource.location.match(/[:\.]([0-9a-z]+)$/i)[1]
    @file_name = "#{new_resource.name}-#{sha}.#{@extension}"
  end
  @current_resource = Chef::Resource::ArtifactPackage.new(@new_resource.name)
  @current_resource
end

action :install do

  pkg = ::File.join(Chef::Config[:file_cache_path],
                         "artifact_packages",
                         file_name)

  directory ::File.dirname(pkg) do
    action :create
    recursive true
  end

  artifact_file pkg do
    location new_resource.location
    checksum new_resource.checksum if new_resource.checksum
    owner new_resource.owner
    group new_resource.group
    nexus_configuration nexus_configuration_object if Chef::Artifact.from_nexus?(new_resource.location)
    download_retries new_resource.download_retries
    after_download new_resource.after_download
  end

  package new_resource.name do
    source pkg
    action :install
  end
end
