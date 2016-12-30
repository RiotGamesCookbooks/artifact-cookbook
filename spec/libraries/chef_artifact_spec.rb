require 'spec_helper'

describe Chef::Artifact do
  let(:node) { double('node', chef_environment: "default") }
  describe ":data_bag_config_for" do
    subject { data_bag_config_for }
    let(:environment) { "default" }
    let(:data_bag_config_for) { described_class.data_bag_config_for(environment, source) }
    let(:source) { Chef::Artifact::DATA_BAG_NEXUS }

    context "when we are using chef-solo" do
      let(:data_bag_item) { {} }

      before do
        Chef::Config.stub(:[]).and_return({solo: true})
        Chef::DataBagItem.stub(:load).and_return(data_bag_item)
      end

      it "loads a normal data bag" do
        expect(data_bag_config_for).to eq(data_bag_item)
      end
    end

    context "when we are not using chef-solo" do
      let(:data_bag_item) { {name: "Test", value: 1} }

      before do
        Chef::EncryptedDataBagItem.stub(:load).and_return(data_bag_item)
      end

      it "loads an encrypted data bag" do
        expect(data_bag_config_for.symbolize_keys).to eq(data_bag_item)
      end
    end

    context "when loading legacy data bag format" do
      let(:data_bag_item) { { 'username' => 'nexus_user', 'password' => 'nexus_user_password'} }

      before do
        Chef::Config.stub(:[]).and_return({solo: true})
        Chef::DataBagItem.stub(:load).and_return(data_bag_item)
      end

      it "loads a normal data bag" do
        expect(data_bag_config_for).to eq(data_bag_item)
      end
    end

    context "when loading environment based legacy nexus data bag format" do
      let(:data_bag_item) { { '*' => { 'username' => 'nexus_user', 'password' => 'nexus_user_password'} } }

      before do
        Chef::Config.stub(:[]).and_return({solo: true})
        Chef::DataBagItem.stub(:load).and_return(data_bag_item)
      end

      it "loads a normal data bag" do
        expect(data_bag_config_for).to eq(data_bag_item)
      end
    end

    context "when loading nexus data bag config" do
      let(:data_bag_item) { { 'nexus' => { 'username' => 'nexus_user', 'password' => 'nexus_user_password'} } }
      let(:nexus_data_bag_item) { { 'username' => 'nexus_user', 'password' => 'nexus_user_password'} }
      before do
        Chef::Config.stub(:[]).and_return({solo: true})
        Chef::DataBagItem.stub(:load).and_return(data_bag_item)
      end

      it "loads a normal data bag" do
        expect(data_bag_config_for).to eq(nexus_data_bag_item)
      end
    end

    context "when loading aws data bag config" do
      let(:data_bag_item) { {
            'nexus' => { 'username' => 'nexus_user', 'password' => 'nexus_user_password' },
            'aws' => { 'access_key_id' => 'my_access_key', 'secret_access_key' => 'my_secret_key' }
      } }
      let(:aws_data_bag_item) { { 'access_key_id' => 'my_access_key', 'secret_access_key' => 'my_secret_key' } }
      let(:source) { Chef::Artifact::DATA_BAG_AWS }
      before do
        Chef::Config.stub(:[]).and_return({solo: true})
        Chef::DataBagItem.stub(:load).and_return(data_bag_item)
      end

      it "loads a normal data bag" do
        expect(data_bag_config_for).to eq(aws_data_bag_item)
      end
    end

    context "when loading aws data bag config that is not there" do
      let(:data_bag_item) { {  'nexus' => { 'username' => 'nexus_user', 'password' => 'nexus_user_password' } } }
      let(:aws_data_bag_item) { { } }
      let(:source) { Chef::Artifact::DATA_BAG_AWS }
      before do
        Chef::Config.stub(:[]).and_return({solo: true})
        Chef::DataBagItem.stub(:load).and_return(data_bag_item)
      end

      it "loads a normal data bag" do
        expect(data_bag_config_for).to eq(aws_data_bag_item)
      end
    end
  end

  describe ":encrypted_data_bag_for" do
    subject { encrypted_data_bag_for }
    let(:environment) { "default" }
    let(:encrypted_data_bag_for) { described_class.encrypted_data_bag_for(environment, data_bag) }
    let(:data_bag) { Chef::Artifact::DATA_BAG }
    let(:data_bag_item) { {name: "Test", value: 1} }

    context "when the data bag has already been loaded" do
      before do
        described_class.stub(:encrypted_data_bags).and_return({"artifact" => data_bag_item})
      end

      it "reads from the cache" do
        described_class.should_receive(:get_from_data_bags_cache).with(data_bag).and_return(data_bag_item)
        described_class.should_not_receive(:encrypted_data_bag_item)
        expect(encrypted_data_bag_for).to eq(data_bag_item)
      end
    end

    context "when the data bag has not been loaded" do
      before do
        described_class.stub(:encrypted_data_bags).and_return({})
      end

      it "looks for an environment named data bag item" do
        described_class.stub(:encrypted_data_bag_item).and_return(data_bag_item)
        described_class.should_receive(:encrypted_data_bag_item).with(data_bag, "default")
        expect(encrypted_data_bag_for).to eq(data_bag_item)
      end

      it "looks for the '_wildcard' data bag item" do
        described_class.stub(:encrypted_data_bag_item).and_return(nil, data_bag_item)
        described_class.should_receive(:encrypted_data_bag_item).with(data_bag, "_wildcard")
        expect(encrypted_data_bag_for).to eq(data_bag_item)
      end

      it "looks for the 'nexus' data bag item" do
        described_class.stub(:encrypted_data_bag_item).and_return(nil, nil, data_bag_item)
        described_class.should_receive(:encrypted_data_bag_item).with(data_bag, "nexus")
        expect(encrypted_data_bag_for).to eq(data_bag_item)
      end
    end
  end

  describe ":encrypted_data_bag_item" do
    subject { encrypted_data_bag_item }
    let(:encrypted_data_bag_item) { described_class.encrypted_data_bag_item(data_bag, data_bag_item) }
    let(:data_bag) { Chef::Artifact::DATA_BAG }
    let(:data_bag_item) { {name: "Test", value: 1} }

    context "when a data bag cannot be found" do
      before do
        error = Net::HTTPServerException.new(nil, nil)
        Chef::EncryptedDataBagItem.stub(:load).and_raise(error)
      end

      it "returns nil" do
        expect(encrypted_data_bag_item).to be_nil
      end
    end

    context "when the data bag cannot be decrypted" do
      before do
        Chef::EncryptedDataBagItem.stub(:load).and_raise(NoMethodError)
      end

      it "raises a DataBagEncryptionError" do
        expect{ encrypted_data_bag_item }.to raise_error(Chef::Artifact::DataBagEncryptionError)
      end
    end
  end

  describe ":from_http?" do
    specify { described_class.from_http?('s3://my.bucket/a/valid/file.tar.gz').should eq(false) }
    specify { described_class.from_http?('http://files3.something.com').should eq(true) }
    specify { described_class.from_http?('https://artifacts.location.riotgames.com/pvpnet-1.0.0.tar.gz').should eq(true) }
    specify { described_class.from_http?('https://s3-us-west-2.amazonaws.com/my.bucket/a/valid/file.tar.gz').should eq(true) }
    specify { described_class.from_http?('ftp://someserver.example.com/file.tgz').should eq(false) }
  end

  describe ":from_nexus?" do
    specify { described_class.from_nexus?('s3://my.bucket/a/valid/file.tar.gz').should eq(false) }
    specify { described_class.from_nexus?('http://files3.something.com').should eq(false) }
    specify { described_class.from_nexus?('https://s3-us-west-2.amazonaws.com/my.bucket/a/valid/file.tar.gz').should eq(false) }
    specify { described_class.from_nexus?('ftp://someserver.example.com/file.tgz').should eq(false) }
    specify { described_class.from_nexus?('com.foo:my-artifact:tgz').should eq(true) }
  end

  describe ":from_s3?" do
    specify { described_class.from_s3?('s3://s3.amazonaws.com/my.bucket/a/valid/file.tar.gz').should eq(true) }
    specify { described_class.from_s3?('s3://s3-us-west-2.amazonaws.com/my.bucket/a/valid/file.tar.gz').should eq(true) }
    specify { described_class.from_s3?('http://files3.something.com').should eq(false) }
    specify { described_class.from_s3?('https://s3-us-west-2.amazonaws.com/my.bucket/a/valid/file.tar.gz').should eq(false) }
  end

  describe ":latest?" do
    specify { described_class.latest?('latest').should eq(true) }
    specify { described_class.latest?('LAtest').should eq(true) }
    specify { described_class.latest?('3.0.1').should eq(false) }
  end

  describe ":snapshot?" do
    specify { described_class.snapshot?('1.0.0-SNAPSHOT').should eq(true) }
    specify { described_class.snapshot?('3.0.1').should eq(false) }
  end

  describe ":get_s3_object" do
    require 'aws-sdk'
    AWS.stub!
    subject { get_s3_object }
    let(:mock_s3_client) { mock('mock_s3_client') }
    let(:mock_s3_bucket) { mock('my-bucket') }
    let(:mock_s3_object) { mock('my-file.tar.gz') }
    let(:stub_buckets_list) { stub('s3buckets') }
    let(:stub_objects_list) { stub('s3ojects') }
    let(:get_s3_object) { described_class.get_s3_object('my-bucket', 'my-file.tar.gz') }

    context "when getting an object from S3" do
      it "loads file normally" do
        stub_buckets_list.stub(:[]).with('my-bucket').and_return(mock_s3_bucket)
        stub_objects_list.stub(:[]).with('my-file.tar.gz').and_return(mock_s3_object)
        AWS::S3.should_receive(:new).with(no_args()).and_return(mock_s3_client)
        mock_s3_client.should_receive(:buckets).and_return(stub_buckets_list)
        mock_s3_bucket.should_receive(:objects).and_return(stub_objects_list)
        mock_s3_bucket.should_receive(:exists?).and_return(true)
        mock_s3_object.should_receive(:exists?).and_return(true)

        get_s3_object
      end
    end

    context "when asking for an S3 bucket that does not exist" do
      it "throws an S3BucketNotFoundError" do
        stub_buckets_list.stub(:[]).with('my-bucket').and_return(mock_s3_bucket)
        AWS::S3.should_receive(:new).with(no_args()).and_return(mock_s3_client)
        mock_s3_client.should_receive(:buckets).and_return(stub_buckets_list)
        mock_s3_bucket.should_receive(:exists?).and_return(false)

        expect{ get_s3_object }.to raise_error(Chef::Artifact::S3BucketNotFoundError)
      end
    end

    context "when asking for an S3 object that does not exist" do
      it "throws an S3ArtifactNotFoundError" do
        stub_buckets_list.stub(:[]).with('my-bucket').and_return(mock_s3_bucket)
        stub_objects_list.stub(:[]).with('my-file.tar.gz').and_return(mock_s3_object)
        AWS::S3.should_receive(:new).with(no_args()).and_return(mock_s3_client)
        mock_s3_client.should_receive(:buckets).and_return(stub_buckets_list)
        mock_s3_bucket.should_receive(:objects).and_return(stub_objects_list)
        mock_s3_bucket.should_receive(:exists?).and_return(true)
        mock_s3_object.should_receive(:exists?).and_return(false)

        expect{ get_s3_object }.to raise_error(Chef::Artifact::S3ArtifactNotFoundError)
      end
    end
  end


  describe ":retrieve_from_s3" do
    require 'aws-sdk'
    AWS.stub!
    subject { retrieve_from_s3 }
    let(:mock_s3_client) { mock('mock_s3_client') }
    let(:mock_output_file) { mock('mock_output_file') }
    let(:mock_s3_bucket) { mock('my-bucket') }
    let(:mock_s3_object) { mock('my-file.tar.gz') }
    let(:stub_buckets_list) { stub('s3buckets') }
    let(:stub_objects_list) { stub('s3ojects') }
    let(:mock_file_contents) { 'test file contents' }
    let(:expected_file_contents) { 'test file contents' }

    context "when getting a file from S3 with credentials" do
      let(:data_bag_item) { { 'aws' => { 'access_key_id' => 'my_access_key', 'secret_access_key' => 'my_secret_key' } } }
      before do
        Chef::Config.stub(:[]).and_return({solo: true})
        Chef::DataBagItem.stub(:load).and_return(data_bag_item)
        described_class.should_receive(:get_s3_object).with("my-bucket", "my-file.tar.gz").and_return(mock_s3_object)
        File.should_receive(:open).with("filename", "wb").and_yield(mock_output_file)
      end

      it "configures AWS correct and reads the file" do
        stub_buckets_list.stub(:[]).with("my-bucket").and_return(mock_s3_bucket)
        stub_objects_list.stub(:[]).with("my-file.tar.gz").and_return(mock_s3_object)

        AWS.should_receive(:config).with({:access_key_id=>"my_access_key", :secret_access_key=>"my_secret_key", :s3 => { :endpoint => 's3.amazonaws.com' }})

        mock_s3_object.should_receive(:read).and_yield(mock_file_contents)
        mock_output_file.should_receive(:size).and_return(11241)
        mock_output_file.should_receive(:write).with(expected_file_contents)

        Chef::Artifact.retrieve_from_s3(node, "s3://s3.amazonaws.com/my-bucket/my-file.tar.gz", "filename")
      end
    end

    context "when getting a file from S3 without credentials" do
      let(:data_bag_item) { { } }
      before do
        Chef::Config.stub(:[]).and_return({solo: true})
        Chef::DataBagItem.stub(:load).and_return(data_bag_item)
        described_class.should_receive(:get_s3_object).with("my-bucket", "my-file.tar.gz").and_return(mock_s3_object)
        File.should_receive(:open).with("filename", "wb").and_yield(mock_output_file)
      end

      it "configures AWS correct and reads the file" do
        stub_buckets_list.stub(:[]).with("my-bucket").and_return(mock_s3_bucket)
        stub_objects_list.stub(:[]).with("my-file.tar.gz").and_return(mock_s3_object)

        AWS.should_receive(:config).with({:s3 => { :endpoint => 's3-us-west-2.amazonaws.com' }})

        mock_s3_object.should_receive(:read).and_yield(mock_file_contents)
        mock_output_file.should_receive(:size).and_return(11241)
        mock_output_file.should_receive(:write).with(expected_file_contents)

        Chef::Artifact.retrieve_from_s3(node, "s3://s3-us-west-2.amazonaws.com/my-bucket/my-file.tar.gz", "filename")
      end
    end
  end
end
