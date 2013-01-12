#
# Cookbook Name:: artifact
# Provider:: deploy
#
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
# Author:: Kyle Allan (<kallan@riotgames.com>)
# Copyright 2012, Riot Games
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
require 'pathname'
require 'uri'
require 'yaml'

attr_reader :release_path
attr_reader :current_path
attr_reader :shared_path
attr_reader :previous_release_path
attr_reader :artifact_root
attr_reader :version_container_path
attr_reader :manifest_file
attr_reader :previous_versions
attr_reader :artifact_location
attr_reader :artifact_version

def load_current_resource
  if latest?(@new_resource.version) && from_http?(@new_resource.artifact_location)
    Chef::Application.fatal! "You cannot specify the latest version for an artifact when attempting to download an artifact using http(s)!"
  end

  if from_nexus?(@new_resource.artifact_location)
    %W{libxml2-devel libxslt-devel}.each do |nokogiri_requirement|
      package nokogiri_requirement do
        action :install
      end.run_action(:install)
    end

    chef_gem "nexus_cli" do
      version "2.0.2"
    end

    group_id, artifact_id, extension = @new_resource.artifact_location.split(':')
    @artifact_version = Chef::Artifact.get_actual_version(node, group_id, artifact_id, @new_resource.version, extension)
    @artifact_location = [group_id, artifact_id, artifact_version, extension].join(':')
  else
    @artifact_version = @new_resource.version
    @artifact_location = @new_resource.artifact_location
  end

  @release_path           = get_release_path
  @current_path           = @new_resource.current_path
  @shared_path            = @new_resource.shared_path
  @artifact_root          = ::File.join(@new_resource.artifact_deploy_path, @new_resource.name)
  @version_container_path = ::File.join(@artifact_root, artifact_version)
  @previous_release_path  = get_previous_release_path
  @previous_versions      = get_previous_versions
  @manifest_file          = ::File.join(@release_path, "manifest.yaml")
  @deploy                 = false
  @current_resource       = Chef::Resource::ArtifactDeploy.new(@new_resource.name)

  @current_resource
end

action :deploy do

  setup_deploy_directories!
  setup_shared_directories!
  Chef::Log.info "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
  Chef::Log.info "Lets see! #{::File.exists?(release_path)}"
  Chef::Log.info "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"

  @deploy = manifest_differences?

  Chef::Log.info "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
  Chef::Log.info "manifest_differences? #{deploy?}"
  Chef::Log.info "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"

  retrieve_artifact!

  recipe_eval(&new_resource.before_deploy) if new_resource.before_deploy

  if deploy?
    recipe_eval(&new_resource.before_extract) if new_resource.before_extract
    if new_resource.is_tarball
      extract_artifact

      Chef::Log.info "(*************************************************)"
      Chef::Log.info "did it extract? #{::File.exist?(::File.join(release_path, 'log4j.xml'))}"
      Chef::Log.info "(*************************************************)"
    else
      copy_artifact
    end
    recipe_eval(&new_resource.after_extract) if new_resource.after_extract

    recipe_eval(&new_resource.before_symlink) if new_resource.before_symlink
    symlink_it_up!
    recipe_eval(&new_resource.after_symlink) if new_resource.after_symlink
  end

  recipe_eval(&new_resource.configure) if new_resource.configure

  if deploy? && new_resource.should_migrate
    recipe_eval(&new_resource.before_migrate) if new_resource.before_migrate
    recipe_eval(&new_resource.migrate) if new_resource.should_migrate
    recipe_eval(&new_resource.after_migrate) if new_resource.after_migrate
  end

  if deploy? || manifest_differences?
    recipe_eval(&new_resource.restart) if new_resource.restart
  end

  recipe_eval(&new_resource.after_deploy) if new_resource.after_deploy

  recipe_eval { write_manifest }

  new_resource.updated_by_last_action(true)
end

# Extracts the artifact defined in the resource call. Handles
# a variety of 'tar' based files (tar.gz, tgz, tar, tar.bz2, tbz)
# and a few 'zip' based files (zip, war, jar).
# 
# @return [void]
def extract_artifact
  recipe_eval do
    case ::File.extname(cached_tar_path)
    when /tar.gz|tgz|tar|tar.bz2|tbz/
      execute "extract_artifact" do
        command "tar xf #{cached_tar_path} -C #{release_path}"
        user new_resource.owner
        group new_resource.group
      end
    when /zip|war|jar/
      package "unzip"
      execute "extract_artifact" do
        command "unzip -q -u -o #{cached_tar_path} -d #{release_path}"
        user new_resource.owner
        group new_resource.group
      end
    else
      Chef::Application.fatal! "Cannot extract artifact because of its extension. Supported types are"
    end
  end
end

# Copies the artifact from its cached path to its release path. The cached path is
# the configured Chef::Config[:file_cache_path]/artifact_deploys
# 
# @example
#   cp /tmp/vagrant-chef-1/artifact_deploys/artifact_test/1.0.0/my-artifact.zip /srv/artifact_test/releases/1.0.0
# 
# @return [void]
def copy_artifact
  recipe_eval do
    execute "copy artifact" do
      command "cp #{cached_tar_path} #{release_path}"
      user new_resource.owner
      group new_resource.group
    end
  end
end

# Returns the file path to the cached artifact the resource is installing.
# 
# @return [String] the path to the cached artifact
def cached_tar_path
  ::File.join(version_container_path, artifact_filename)
end

# Returns the filename of the artifact being installed when the LWRP
# is called. Depending on how the resource is called in a recipe, the
# value returned by this method will change. If from_nexus?, return the
# concatination of "artifact_id-version.extension" otherwise return the
# basename of where the artifact is located.
# 
# @example
#   When: new_resource.artifact_location => "com.artifact:my-artifact:1.0.0:tgz"
#     artifact_filename => "my-artifact-1.0.0.tgz"
#   When: new_resource.artifact_location => "http://some-site.com/my-artifact.jar"
#     artifact_filename => "my-artifact.jar"
# 
# @return [String] the artifacts filename
def artifact_filename
  if from_nexus?(new_resource.artifact_location)    
    group_id, artifact_id, version, extension = artifact_location.split(":")
    unless extension
      extension = "jar"
    end
   "#{artifact_id}-#{version}.#{extension}"
  else
    ::File.basename(artifact_location)
  end
end

private

  def delete_previous_versions(options = {})
    keep = options[:keep] || 0
    delete_first = total = previous_versions.length

    if total == 0 || total <= keep
      return true
    end

    delete_first -= keep

    Chef::Log.info "artifact_deploy[delete_previous_versions] is deleting #{delete_first} of #{total} old versions (keeping: #{keep})"

    to_delete = previous_versions.shift(delete_first)

    to_delete.each do |version|
      delete_cached_files_for(version.basename)
      delete_release_path_for(version.basename)
      Chef::Log.info "artifact_deploy[delete_previous_versions] #{version.basename} deleted"
    end
  end

  def delete_cached_files_for(version)
    FileUtils.rm_rf ::File.join(artifact_root, version)
  end

  def delete_release_path_for(version)
    FileUtils.rm_rf ::File.join(new_resource.deploy_to, 'releases', version)
  end

  def manifest_differences?
    if get_previous_release_version != new_resource.version
      Chef::Log.info "No current version installed for #{new_resource.name}." if get_previous_release_version.nil?
      Chef::Log.info "Currently installed version of artifact is #{get_previous_release_version}." unless get_previous_release_version.nil?
      Chef::Log.info "Installing version, #{artifact_version} for #{new_resource.name}."
      return true
    end
    if previous_release_path.nil? || !::File.exists?(::File.join(previous_release_path, "manifest.yaml"))
      Chef::Log.warn "No manifest file found for current version, assuming there are differences."
      return true
    end

    Chef::Log.info "Loading manifest.yaml file from directory: #{release_path}"
    original_manifest = YAML.load_file(::File.join(release_path, "manifest.yaml"))
    
    current_manifest = create_manifest(release_path)
    !!original_manifest.find { |key, value| !current_manifest.has_key?(key) || value != current_manifest[key] }
  end

  def deploy?
    @deploy
  end

  def get_previous_release_path
    if ::File.exists?(current_path)
      ::File.readlink(current_path)
    end
  end

  def get_previous_release_version
    if ::File.exists?(current_path)
      ::File.basename(get_previous_release_path)
    end
  end

  # Returns a path to the artifact being installed by
  # the configured resource.
  # 
  # @example
  #   When: 
  #     new_resource.deploy_to = "/srv/artifact_test" and artifact_version = "1.0.0"
  #       get_release_path => "/srv/artifact_test/releases/1.0.0"
  # 
  # @return [String] the artifacts release path
  def get_release_path
    ::File.join(new_resource.deploy_to, "releases", artifact_version)
  end

  def get_previous_versions
    versions = Dir[::File.join(artifact_root, '**')].collect do |v|
      Pathname.new(v)
    end

    versions.reject! { |v| v.to_s == version_container_path }

    versions.sort_by(&:mtime)
  end

  def symlink_it_up!
    new_resource.symlinks.each do |key, value|
      directory "#{new_resource.shared_path}/#{key}" do
        owner new_resource.owner
        group new_resource.group
        mode '0755'
        recursive true
      end

      link "#{release_path}/#{value}" do
        to "#{new_resource.shared_path}/#{key}"
        owner new_resource.owner
        group new_resource.group
      end
    end
  end

  def setup_deploy_directories!
    recipe_eval do
      [ version_container_path, release_path, shared_path ].each do |path|
        directory path do
          owner new_resource.owner
          group new_resource.group
          mode '0755'
          recursive true
        end
      end
    end
  end

  def setup_shared_directories!
    recipe_eval do
      new_resource.shared_directories.each do |dir|
        directory "#{shared_path}/#{dir}" do
          owner new_resource.owner
          group new_resource.group
          mode '0755'
          recursive true
        end
      end
    end
  end

  def retrieve_artifact!
    recipe_eval do
      if from_http?(new_resource.artifact_location)
        retrieve_from_http
      elsif from_nexus?(new_resource.artifact_location)
        retrieve_from_nexus
      elsif ::File.exist?(new_resource.artifact_location)
        retrieve_from_local
      else
        Chef::Application.fatal! "Cannot retrieve artifact #{new_resource.artifact_location}! Please make sure the artifact exists in the specified location."
      end
    end
  end

  def from_http?(location)
    location =~ URI::regexp(['http', 'https'])
  end

  def from_nexus?(location)
    location.split(":").length > 2
  end

  def latest?(version)
    version.casecmp("latest") == 0
  end

  def retrieve_from_http
    remote_file cached_tar_path do
      source new_resource.artifact_location
      owner new_resource.owner
      group new_resource.group
      checksum new_resource.artifact_checksum
      backup false

      action :create
    end
  end

  def retrieve_from_nexus
    ruby_block "retrieve from nexus" do
      block do
        require 'nexus_cli'
        unless ::File.exists?(cached_tar_path) && Chef::ChecksumCache.checksum_for_file(cached_tar_path) == new_resource.artifact_checksum
          config = Chef::Artifact.nexus_config_for(node)
          remote = NexusCli::RemoteFactory.create(config, false)
          remote.pull_artifact(artifact_location, version_container_path)
        end
      end
    end
  end

  def retrieve_from_local
    file cached_tar_path do
      content ::File.open(new_resource.artifact_location).read
      owner new_resource.owner
      group new_resource.group
    end
  end

  def create_manifest(files_path)
    require 'digest'
    Chef::Log.info "Generating manifest for files in #{files_path}"
    files_in_release_path = nil
    Dir.chdir(files_path) do |path|
      files_in_release_path = Dir.glob("**/*").reject { |file| ::File.directory?(file) || file == "manifest.yaml" }
    end
    
    files_in_release_path.inject(Hash.new) do |map, file|
      map[file] = Digest::SHA1.hexdigest(file)
      map
    end
  end

  def write_manifest
    manifest = create_manifest(release_path)
    require 'yaml'
    Chef::Log.info "Writing manifest.yaml file to #{manifest_file}"
    ::File.open(manifest_file, "w") { |file| file.puts YAML.dump(manifest) }
  end