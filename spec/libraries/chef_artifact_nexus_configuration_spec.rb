require 'spec_helper'

describe Chef::Artifact::NexusConfiguration do
  describe ":from_data_bag" do
    let(:from_data_bag) { described_class.from_data_bag }
    let(:config_double) { double(:solo => true) }
    let(:data_bag) do
      {
        'url' => 'www.fake-url.com',
        'repository' => 'repo',
        'username' => 'foo',
        'password' => 'bar'
      }
    end

    before do
      Chef::Config.stub(:[]).and_return(config_double)
      Chef::Artifact.stub(:data_bag_config_for).and_return(data_bag)
    end

    context "when there is no data bag to load" do
      let(:data_bag) { nil }

      it "returns nil" do
        expect(from_data_bag).to be_nil
      end
    end

    context "when there is a data bag to load" do
      it "returns a Chef::Artifact::NexusConfiguration" do
        expect(from_data_bag).to be_a(Chef::Artifact::NexusConfiguration)
      end

      context "when ssl_verify is not in the data bag" do
        it "returns with ssl_verify set to true" do
          expect(from_data_bag.ssl_verify).to be_true
        end
      end

      context "when ssl_verify is in the data bag and is false" do
        let(:data_bag) do
          {
            'url' => 'www.fake-url.com',
            'repository' => 'repo',
            'username' => 'foo',
            'password' => 'bar',
            'ssl_verify' => false            
          }
        end

        it "returns with ssl_verify set to false" do
          expect(from_data_bag.ssl_verify).to be_false
        end
      end
    end
  end

  describe "#inspect" do
    subject do
      described_class.new("http://fake-url.com/", "repository", "my-user", "my-pass")
    end
    let(:inspect) { subject.inspect }

    it "masks the password instance variable value" do
      expect(inspect).to match(/@password="MASKED"/)
    end
  end
end
