require 'minitest/autorun'

describe "file" do
  
  describe "when you create a new file" do
    it "exists" do
      assert File.exists?("/tmp/maven.tar.gz")
    end
  end

  describe "when you try to download the same file twice" do
    it "does not download the file a second time" do
      chef_mtime = File.read("/tmp/artifact_mtime").chomp
      test_mtime = File.mtime("/tmp/maven.tar.gz").to_s
      assert chef_mtime == test_mtime
    end
  end
end
