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
require 'chef/mixin/create_path'

attr_reader :file_location
attr_reader :nexus_configuration
attr_reader :nexus_connection

include Chef::Artifact::Helpers
include Chef::Mixin::CreatePath

def load_current_resource
  create_cache_path
  if Chef::Artifact.from_nexus?(new_resource.location)

    chef_gem "nexus_cli" do
      version "4.0.2"
    end

    @nexus_configuration = new_resource.nexus_configuration
    @nexus_connection = Chef::Artifact::Nexus.new(node, nexus_configuration)
  elsif Chef::Artifact.from_s3?(@new_resource.location)
    chef_gem "aws-sdk" do
      version "1.29.0"
    end
  end
  @file_location = new_resource.location
  @file_path = new_resource.path

  @current_resource = Chef::Resource::ArtifactFile.new(@new_resource.name)
  @current_resource
end

action :create do
  retries = new_resource.download_retries
  begin
    if Chef::Artifact.from_s3?(file_location)
      unless ::File.exists?(new_resource.path) && checksum_valid?
        Chef::Artifact.retrieve_from_s3(node, file_location, new_resource.path)
        run_proc :after_download
      end
    elsif Chef::Artifact.from_nexus?(file_location)
      unless ::File.exists?(new_resource.path) && checksum_valid? && (!Chef::Artifact.snapshot?(file_location) || !Chef::Artifact.latest?(file_location))
        begin
          if ::File.exists?(new_resource.path)
            if Digest::SHA1.file(new_resource.path).hexdigest != nexus_connection.get_artifact_sha(file_location)
              nexus_connection.retrieve_from_nexus(file_location, ::File.dirname(new_resource.path))
            end
          else
            nexus_connection.retrieve_from_nexus(file_location, ::File.dirname(new_resource.path))
          end
          if nexus_connection.get_artifact_filename(file_location) != ::File.basename(new_resource.path)
            ::File.rename(::File.join(::File.dirname(new_resource.path), nexus_connection.get_artifact_filename(file_location)), new_resource.path)
          end
          run_proc :after_download
        rescue NexusCli::PermissionsException => e
          msg = "The artifact server returned 401 (Unauthorized) when attempting to retrieve this artifact. Confirm that your credentials are correct."
          raise Chef::Artifact::ArtifactDownloadError.new(msg)
        end
      end
    else
      remote_file_resource.run_action(:create)
    end
    raise Chef::Artifact::ArtifactChecksumError unless checksum_valid?
    write_checksum if Chef::Artifact.from_nexus?(file_location) || Chef::Artifact.from_s3?(file_location)
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

  if cached_checksum_exists?
    if Chef::Artifact.from_nexus?(file_location)
      if Chef::Artifact.snapshot?(file_location) || Chef::Artifact.latest?(file_location)
        return Digest::SHA1.file(new_resource.path).hexdigest == nexus_connection.get_artifact_sha(file_location)
      end
    end
    return Digest::SHA256.file(new_resource.path).hexdigest == read_checksum
  end

  if Chef::Artifact.from_nexus?(file_location)
    Digest::SHA1.file(new_resource.path).hexdigest == nexus_connection.get_artifact_sha(file_location)
  else
    if new_resource.checksum
      Digest::SHA256.file(new_resource.path).hexdigest == new_resource.checksum
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
  @remote_file_resource ||= remote_file new_resource.path do
    source file_location
    checksum new_resource.checksum
    owner new_resource.owner
    group new_resource.group
    backup false
    action :nothing
  end
end

private
  # A wrapper that calls Chef::Artifact:run_proc
  #
  # @param name     [Symbol] the name of the proc to execute
  #
  # @return [void]
  def run_proc(name)
    execute_run_proc("artifact_file", new_resource, name)
  end

  # Scrubs the file_location and returns the path to 
  # the resource's checksum file.
  #
  # @return [String]
  def cached_checksum
    scrubbed_uri = file_location.gsub(/\W/, '_')[0..63]
    uri_md5 = Digest::MD5.hexdigest(file_location)
    ::File.join(cache_path, "#{scrubbed_uri}-#{uri_md5}")
  end

  # Creates a the cache path if it does not already exist
  #
  # @return [String] the created path
  def create_cache_path
    create_path(cache_path)
  end

  # Returns the artifact_file cache path for cached checksums
  #
  # @return [String]
  def cache_path
    ::File.join(Chef::Config[:file_cache_path], "artifact_file")
  end

  # Returns true when the cached_checksum file exists, false otherwise
  #
  # @return [Boolean]
  def cached_checksum_exists?
    ::File.exists?(cached_checksum)
  end

  # Writes a file to file_cache_path. This file contains a SHA256 digest of the 
  # artifact file. Returns the result of the file.puts command, which will be nil.
  #
  # @return [NilClass]
  def write_checksum
    ::File.open(cached_checksum, "w") { |file| file.puts Digest::SHA256.file(new_resource.path).hexdigest }
  end

  # Reads the cached_checksum
  #
  # @return [String]
  def read_checksum
    ::File.read(cached_checksum).strip
  end
