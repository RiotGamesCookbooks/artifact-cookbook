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

action :install do
  sha = Digest::SHA1.hexdigest new_resource.location
  ext = new_resource.location.match(/[:\.]([0-9a-z]+)$/i)[1]

  pkg = ::File.join(Chef::Config[:file_cache_path],
                         "artifact_packages",
                         "#{new_resource.name}-#{sha}.#{ext}")

  directory ::File.dirname(pkg) do
    action :create
    recursive true
  end

  artifact_file pkg do
    location new_resource.location
    checksum new_resource.checksum if new_resource.checksum
    owner new_resource.owner
    group new_resource.group
    download_retries new_resource.download_retries
  end

  package new_resource.name do
    source pkg
    action :install
  end
end
