#
# Cookbook Name:: artifact
# Resource:: deploy
#
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
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

require 'uri'

actions :deploy

attribute :artifact_name, :kind_of      => String, :required => true, :name_attribute => true
attribute :artifact_location, :kind_of  => String
attribute :artifact_url, :kind_of       => String, :regex => URI.regexp(['http', 'https'])
attribute :artifact_checksum, :kind_of  => String
attribute :deploy_to, :kind_of          => String, :required => true
attribute :version, :kind_of            => String
attribute :owner, :kind_of              => String, :required => true, :regex => Chef::Config[:user_valid_regex]
attribute :group, :kind_of              => String, :required => true, :regex => Chef::Config[:user_valid_regex]
attribute :environment, :kind_of        => Hash, :default => Hash.new
attribute :symlinks, :kind_of           => Hash, :default => Hash.new
attribute :shared_directories, :kind_of => Array, :default => %w{ system pids log }
attribute :before_extract, :kind_of     => Proc
attribute :before_migrate, :kind_of     => Proc
attribute :after_migrate, :kind_of      => Proc
attribute :migrate, :kind_of            => Proc
attribute :restart_proc, :kind_of       => Proc
attribute :before_symlink, :kind_of     => Proc
attribute :force, :kind_of              => [ TrueClass, FalseClass ], :default => false
attribute :should_migrate, :kind_of     => [ TrueClass, FalseClass ], :default => false
attribute :keep, :kind_of               => Integer, :default => 2
attribute :is_tarball, :kind_of         => [ TrueClass, FalseClass ], :default => true


# This is to support deprecated attribute artifact_url.
attr_writer :artifact_location

def initialize(*args)
  super
  @action = :deploy
end

def artifact_deploy_path
  "#{Chef::Config[:file_cache_path]}/artifact_deploys"
end

def current_path
  "#{self.deploy_to}/current"
end

def release_path
  "#{self.deploy_to}/releases/#{self.version}"
end

def shared_path
  "#{self.deploy_to}/shared"
end
