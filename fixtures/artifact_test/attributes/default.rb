#
# Cookbook Name:: artifact_test
# Attribute:: default
#

default[:artifact_test][:location]  = "http://artifacts.example.com/artifact_test-1.2.3.tgz"
default[:artifact_test][:version]   = "1.2.3"
default[:artifact_test][:deploy_to] = "/srv/artifact_test"