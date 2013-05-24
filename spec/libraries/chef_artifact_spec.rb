require 'spec_helper'

describe Chef::Artifact do
  let(:node) { double('node', chef_environment: "default") }

  describe ":nexus_config_for" do
    subject { nexus_config_for }
    let(:nexus_config_for) { described_class.nexus_config_for(node) }

    context "when we are using chef-solo" do
      let(:data_bag_item) { {} }

      before do
        Chef::Config.stub(:[]).and_return({solo: true})
        Chef::DataBagItem.stub(:load).and_return(data_bag_item)
      end

      it "loads a normal data bag" do
        expect(nexus_config_for).to eq(data_bag_item)
      end
    end

    context "when we are not using chef-solo" do
      let(:data_bag_item) { {name: "Test", value: 1} }

      before do
        Chef::EncryptedDataBagItem.stub(:load).and_return(data_bag_item)
      end

      it "loads an encrypted data bag" do
        expect(nexus_config_for.symbolize_keys).to eq(data_bag_item)
      end      
    end
  end

  describe ":encrypted_data_bag_for" do
    subject { encrypted_data_bag_for }
    let(:encrypted_data_bag_for) { described_class.encrypted_data_bag_for(node, data_bag) }
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
end
