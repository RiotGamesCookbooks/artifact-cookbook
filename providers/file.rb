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
attr_reader :nexus_configuration
attr_reader :nexus_connection

def load_current_resource
  if Chef::Artifact.from_nexus?(new_resource.location)
    chef_gem "nexus_cli" do
      version "4.0.2"
    end

    @nexus_configuration = new_resource.nexus_configuration
    @nexus_connection = Chef::Artifact::Nexus.new(node, nexus_configuration)
  end
  @file_location = new_resource.location

  @current_resource = Chef::Resource::ArtifactFile.new(@new_resource.name)
  @current_resource
end

action :create do
  retries = new_resource.download_retries
  begin
    if Chef::Artifact.from_s3?(file_location)
      unless ::File.exists?(new_resource.name) && checksum_valid?
        Chef::Artifact.retrieve_from_s3(node, file_location, new_resource.name)
      end
    elsif Chef::Artifact.from_nexus?(file_location)
      unless ::File.exists?(new_resource.name) && checksum_valid?
        begin
          nexus_connection.retrieve_from_nexus(file_location, ::File.dirname(new_resource.name))
        rescue NexusCli::PermissionsException => e
          msg = "The artifact server returned 401 (Unauthorized) when attempting to retrieve this artifact. Confirm that your credentials are correct."
          raise Chef::Artifact::ArtifactDownloadError.new(msg)
        end
      end
    else
      remote_file_resource.run_action(:create)
    end
    raise Chef::Artifact::ArtifactChecksumError unless checksum_valid?
  rescue Chef::Artifact::ArtifactChecksumError => e
    if retries > 0
      retries -= 1
      Chef::Log.warn "[artifact_file] Downloaded file checksum does not match the provided checksum. Retrying - #{retries} attempt(s) left."
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
  if Chef::Artifact.from_nexus?(file_location)
    Digest::SHA1.file(new_resource.name).hexdigest == nexus_connection.get_artifact_sha(file_location)
  else
    if new_resource.checksum
      Digest::SHA256.file(new_resource.name).hexdigest == new_resource.checksum
    else
      Chef::Log.debug "[artifact_file] No checksum provided for artifact_file, assuming checksum is valid."
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
