require 'minitest/autorun'

describe "file" do
  
  describe "when you create a new file" do
    it "exists" do
      assert File.exists?("/tmp/maven.tar.gz")
    end
  end
end
