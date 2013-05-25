require 'minitest/autorun'

describe "file" do
  
  describe "when you create a new file" do
    it "exists" do
      assert File.exists?("/srv/file_test/")
    end

    it "no longer has the deleted files" do
      refute File.exists?("/srv/artifact_test/current/artifact_test_app/lib/bar.rb")
    end
  end
end
