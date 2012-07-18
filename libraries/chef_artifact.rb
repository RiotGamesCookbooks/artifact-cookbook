class Chef
  module Artifact
    DATA_BAG = "artifact"

    class << self
      def nexus_config_for(node)
        data_bag_key = "nexus"
        begin
          data_bag_item = Chef::EncryptedDataBagItem.load(DATA_BAG, data_bag_key)
        rescue Net::HTTPServerException => e
          raise EncryptedDataBagNotFound.new(data_bag_key)
        end

        config = data_bag_item[node.chef_environment] || data_bag_item["*"]
        unless config
          raise EnvironmentNotFound.new(data_bag_key, node.chef_environment)
        end
        config
      end
    end
  end
end
