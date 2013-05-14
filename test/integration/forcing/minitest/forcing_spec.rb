require 'minitest/autorun'

describe "forcing" do
  
  describe "when an artifact with the same version but different files is installed" do
    it "has the new files" do
      assert File.exists?("/srv/artifact_test/current/lib/foo.rb")
    end

    it "no longer has the deleted files" do
      refute File.exists?("/srv/artifact_test/current/lib/bar.rb")
    end
  end
end
