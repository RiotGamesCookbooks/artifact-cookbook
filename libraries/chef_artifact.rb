class Chef
  module Artifact
    DATA_BAG = "artifact".freeze
    NEXUS_DBI = "nexus".freeze

    class << self
      # Return the nexus data bag item. An encrypted data bag item will be used if we are
      # running as Chef Client and a standard data bag item will be used if running as
      # Chef Solo
      #
      # @return [Chef::DataBagItem, Chef::EncryptedDataBagItem]
      def load_nexus_dbi
        if Chef::Config[:solo]
          Chef::DataBagItem.load(DATA_BAG, NEXUS_DBI)
        else
          Chef::EncryptedDataBagItem.load(DATA_BAG, NEXUS_DBI)
        end
      rescue Net::HTTPServerException
        raise EncryptedDataBagNotFound.new(NEXUS_DBI)
      end

      def nexus_config_for(node)
        data_bag_item = load_nexus_dbi

        config = data_bag_item[node.chef_environment] || data_bag_item["*"]
        unless config
          raise EnvironmentNotFound.new(NEXUS_DBI, node.chef_environment)
        end
        config
      end

      def get_actual_version(node, artifact_location, version)
        if version.casecmp("latest") == 0
          require 'nexus_cli'
          config = nexus_config_for(node)
          remote = NexusCli::RemoteFactory.create(config)
          Nokogiri::XML(remote.get_artifact_info(artifact_location)).xpath("//version").first.content()
        else
          version
        end
      end
    end
  end
end
