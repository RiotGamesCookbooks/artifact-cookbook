require 'spec_helper'

describe Chef::Artifact do

  describe ":nexus_config_for" do
    subject { nexus_config_for }
    let(:nexus_config_for) { described_class.nexus_config_for(node) }
    let(:node) { double('node', chef_environment: "default") }

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

      context "when the same data bag is being loaded again" do

        before do
          Chef::EncryptedDataBagItem.stub(:load).and_return(data_bag_item)
        end

        it "is loaded from the class variable" do
          nexus_config_for
          expect(described_class.encrypted_data_bags).to include("artifact")
          expect(nexus_config_for.symbolize_keys).to eq(data_bag_item)
        end
      end
    end
  end
end
