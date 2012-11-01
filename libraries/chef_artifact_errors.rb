class Chef
  module Artifact
    class ArtifactError < StandardError; end

    class EncryptedDataBagNotFound < ArtifactError
      attr_reader :data_bag_key

      def initialize(data_bag_key)
        @data_bag_key = data_bag_key
      end

      def message
        "[artifact] Unable to locate the Artifact encrypted data bag '#{DATA_BAG}' or data bag item '#{data_bag_key}' for your environment."
      end
    end

    class EnvironmentNotFound < ArtifactError
      attr_reader :data_bag_key
      attr_reader :environment

      def initialize(data_bag_key, environment)
        @data_bag_key = data_bag_key
        @environment = environment
      end

      def message
        "[artifact] Unable to locate the Artifact data bag item '#{data_bag_key}' for your environment '#{environment}'."
      end
    end
  end
end
