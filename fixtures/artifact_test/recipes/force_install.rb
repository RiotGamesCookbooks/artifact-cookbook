artifact_deploy "artifact_test" do
  version node[:artifact_test][:version]
  artifact_location "/tmp/kitchen-chef-solo/cookbooks/artifact/fixtures/artifact_test_force-1.2.3.tgz"
  artifact_checksum node[:artifact_test][:checksum]
  deploy_to node[:artifact_test][:deploy_to]
  owner "artifacts"
  group "artifact"
  force true
  remove_on_force true
  action :deploy
end
