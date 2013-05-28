#
# Cookbook Name:: artifact
# Provider:: file
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
attr_reader :file_location

def load_current_resource
  @from_nexus = Chef::Artifact.from_nexus?(new_resource.location)
  @file_location = from_nexus? ? Chef::Artifact.artifact_download_url_for(node, new_resource.location) : new_resource.location
  
  @current_resource = Chef::Resource::ArtifactFile.new(@new_resource.name)
  #@current_resource.checksum = 
  @current_resource
end

action :create do
  unless ::File.exist?(new_resource.name)
    begin
      retries = new_resource.retries
      remote_file_resource.run_action(:create)
      raise ArtifactChecksumError unless checksum_valid?
    rescue ArtifactChecksumError => e
      if retries > 0
        retries -= 1
        Chef::Log.info "blah blah"
        retry
      end
    end
  end
end

def checksum_valid?
  if from_nexus?
    # Check SHA1
  else
    true
  end
end

def remote_file_resource
  @resource ||= remote_file new_resource.name do
    source file_location
    checksum new_resource.checksum
    owner new_resource.owner
    group new_resource.group
    backup false
    action :nothing
  end
  @resource
end

def from_nexus?
  @from_nexus
end
