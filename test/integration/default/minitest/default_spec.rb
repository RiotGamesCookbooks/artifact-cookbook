require 'minitest/autorun'

describe "artifact_deploy" do
  it "makes the deploy_to directory" do
    assert File.exists?("/srv/artifact_test")
  end
end
