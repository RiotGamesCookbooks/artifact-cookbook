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

  if from_nexus?
    chef_gem "nexus_cli" do
      version "3.0.0"
    end

    @file_location = Chef::Artifact.artifact_download_url_for(node, new_resource.location)
  else
    @file_location = new_resource.location
  end

  @current_resource = Chef::Resource::ArtifactFile.new(@new_resource.name)
  @current_resource
end

action :create do
  retries = new_resource.download_retries
  begin
    unless ::File.exists?(new_resource.name) && checksum_valid?
      remote_file_resource.run_action(:create)
    end
    raise Chef::Artifact::ArtifactChecksumError unless checksum_valid?
  rescue Chef::Artifact::ArtifactChecksumError => e
    if retries > 0
      retries -= 1
      Chef::Log.info "[artifact_file] Downloaded file checksum does not match the provided checksum. Retrying - #{retries} attempt(s) left."
      retry
    end
    raise Chef::Artifact::ArtifactChecksumError
  end
end

# For a Nexus artifact, checks the downloaded file's SHA1 checksum
# against the Nexus Server's entry for the file. For normal HTTP artifact,
# check the passed through checksum or just assume the file is fine.
#
# @return [Boolean] true if the downloaded file's checksum
#   matches the checksum on record, false otherwise.
def checksum_valid?
  require 'digest'
  if from_nexus?
    Digest::SHA1.file(new_resource.name).hexdigest == Chef::Artifact.get_artifact_sha(node, new_resource.location)
  else
    if new_resource.checksum
      Digest::SHA256.file(new_resource.name).hexdigest == new_resource.checksum
    else
      Chef::Log.info "[artifact_file] No checksum provided for artifact_file, assuming checksum is valid."
      true
    end
  end
end

# Creates a remote_file resource that will download the artifact
# and has default idempotency. The action is set to nothing so that
# it can be called later.
#
# @return [Chef::Resource::RemoteFile]
def remote_file_resource
  @remote_file_resource ||= remote_file new_resource.name do
    source file_location
    checksum new_resource.checksum
    owner new_resource.owner
    group new_resource.group
    backup false
    action :nothing
  end
end

# @return [Boolean]
def from_nexus?
  @from_nexus
end
