#
# Cookbook Name:: artifact_test
# Recipe:: default
#
# Copyright 2012, Riot Games
#
# All rights reserved - Do Not Redistribute
#

group "artifact"
user "artifacts"

artifact_file "" do
  location ""
  checksum ""
  owner "artifacts"
  group "artifact"
end
