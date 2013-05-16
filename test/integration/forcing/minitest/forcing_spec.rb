require 'minitest/autorun'

describe "forcing" do
  
  describe "when an artifact with the same version but different files is installed" do
    it "has the new files" do
      assert File.exists?("/srv/artifact_test/current/artifact_test_app/lib/foo.rb")
    end

    it "no longer has the deleted files" do
      refute File.exists?("/srv/artifact_test/current/artifact_test_app/lib/bar.rb")
    end
  end
end
