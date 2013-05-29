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

    class DataBagEncryptionError < ArtifactError
      def message
        "[artifact] An error occured while decrypting the data bag item. Your secret key may be incorrect or you may be using Chef 11 to read a Chef 10 data bag."
      end
    end

    class ArtifactChecksumError < ArtifactError
      def message
        "[artifact] Downloaded file checksum does not match the provided checksum. Your download may be corrupted or your checksum may not be correct."
      end
    end
  end
end
