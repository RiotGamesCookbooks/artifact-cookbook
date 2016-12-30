class Chef
  module Artifact
    DATA_BAG = "artifact".freeze
    WILDCARD_DATABAG_ITEM = "_wildcard".freeze
    DATA_BAG_NEXUS = 'nexus'.freeze
    DATA_BAG_AWS = 'aws'.freeze

    module File

      # Returns true if the given file is a symlink.
      #
      # @param  path [String] the path to the file to test
      #
      # @return [Boolean]
      def symlink?(path)
        if windows?
          require 'chef/win32/file'
          return Chef::ReservedNames::Win32::File.symlink?(path)
        end
        ::File.symlink?(path)
      end

      # Returns the value of the readlink method.
      #
      # @param  path [String] the path to a symlink
      #
      # @return [String] the path that the symlink points to
      def readlink(path)
        if windows?
          require 'chef/win32/file'
          return Chef::ReservedNames::Win32::File.readlink(path)
        end
        ::File.readlink(path)
      end

      # Generates a command to execute that either uses the Unix cp
      # command or the Windows copy command.
      #
      # @param  source [String] the file to copy
      # @param  destination [String] the path to copy the source to
      #
      # @return [String] a useable command to copy a file
      def copy_command_for(source, destination)
        if windows?
          %Q{copy "#{source}" "#{destination}"}.gsub(::File::SEPARATOR, ::File::ALT_SEPARATOR)
        else
         "cp -R #{source} #{destination}"
        end
      end

      # @return [Fixnum or nil]
      def windows?
        Chef::Platform.windows?
      end
    end

    class << self
      include Chef::Artifact::File

      # Loads the encrypted data bag item and returns credentials
      # for the environment or for a default key.
      #
      # @param  environment [String] the environment
      # @param  source [String] the deployment source to load configuration for
      #
      # @return [Chef::DataBagItem] the data bag item
      def data_bag_config_for(environment, source)
        data_bag_item = if Chef::Config[:solo]
          Chef::DataBagItem.load(DATA_BAG, WILDCARD_DATABAG_ITEM) rescue {}
        else
          encrypted_data_bag_for(environment, DATA_BAG)
        end

        # support new format
        return data_bag_item[source] if data_bag_item.has_key?(source)

        # backwards compatible for old data bag formats using nexus
        return data_bag_item if DATA_BAG_NEXUS == source

        # no config found for source
        {}
      end

      # Downloads a file to disk from an Amazon S3 bucket
      #
      # @param  node [Chef::Node] the node
      # @param  source_file [String] a s3 url that represents the artifact in the form: s3://<endpoint>/<bucket>/<object-path>
      # @param  destination_file [String] a path to download the artifact to
      #
      def retrieve_from_s3(node, source_file, destination_file)
        begin
          require 'aws-sdk'
          config = data_bag_config_for(node.chef_environment, DATA_BAG_AWS)
          s3_endpoint, bucket_name, object_name = parse_s3_url(source_file)
          endpoint_parts = s3_endpoint.split('.')
          endpoint = endpoint_parts[0]
          # Set Region
          region = endpoint[3,-1]
          if region.nil? || region == 'external-1'
            region = 'us-east-1'
          end
          # Set Config
          Aws.config[:region] = region
          if config.empty?
            Chef::Log.debug("Config not found for databag AWS. Using Instance Profile Credentials")
            Aws.config[:credentials] = Aws::InstanceProfileCredentials.new()
          else
            Chef::Log.debug("Config found for databag AWS. Using databag for credentials")
            Aws.config[:credentials] = Aws::Credentials.new(
                config['access_key_id'],
                config['secret_access_key']
            )
          end
          Chef::Log.debug("Downloading #{object_name} from S3 bucket #{bucket_name}")
          # Retrieve S3 Object
          client = Aws::S3::Client.new()
          object = client.get_object(
              response_target: destination_file,
              bucket: bucket_name,
              key: object_name
          )
          Chef::Log.debug("File #{destination_file} is #{object.content_length} bytes on disk")

        rescue URI::InvalidURIError
          Chef::Log.warn("Expected an S3 URL but found #{source_file}")
          raise
        end
      end

      # Parse a source url to retrieve the specific parts required to interact with the object on S3.
      #
      # @example
      #   s3_endpoint, bucket_name, object_name = Chef::Artifact.parse_s3_url('s3://s3.amazonaws.com/my-bucket/my-file.txt')
      #
      # @param  source_url [String] Source url to parse
      #
      # @return [Array] An array containing the S3 endpoint, Bucket Name and Object Name
      def parse_s3_url(source_url)
        protocol, s3_endpoint, bucket_and_object = URI.split(source_url).compact
        path_parts = bucket_and_object[1..-1].split('/')
        bucket_name = path_parts[0]
        object_name = path_parts[1..-1].join('/')
        [s3_endpoint, bucket_name, object_name]
      end

      # Returns true when the artifact is believed to be from a
      # Nexus source.
      #
      # @param  location [String] the artifact_location
      #
      # @return [Boolean] true when the location is a colon-separated value
      def from_nexus?(location)
        !from_http?(location) && location.split(":").length > 2
      end

      # Returns true when the artifact is believed to be from an
      # S3 bucket.
      #
      # @param  location [String] the artifact_location
      #
      # @return [Boolean] true when the location matches s3
      def from_s3?(location)
        location_of_type(location, 's3')
      end

      # Returns true when the artifact is believed to be from an
      # http source.
      #
      # @param  location [String] the artifact_location
      #
      # @return [Boolean] true when the location matches http or https.
      def from_http?(location)
        location_of_type(location, %w(http https))
      end

      # Returns true when the location URI scheme matches the type
      #
      # @param  location [String] the location URI to check
      # @param  uri_type [Array] list of URI types to check
      #
      # @return [Boolean] true when the location matches the given URI type
      def location_of_type(location, uri_type)
        not (location =~ URI::regexp(uri_type)).nil?
      end

      # Convenience method for determining whether a String is "latest"
      #
      # @param  version [String] the version of the configured artifact to check
      #
      # @return [Boolean] true when version matches (case-insensitive) "latest"
      def latest?(version)
        version.casecmp("latest") == 0
      end

      # Convenience metho for determining whether a version is a snapshot
      # version.
      #
      # @param version [String] the version of the configured artifact to check
      #
      # @return [Boolean] true if the version ends with "-SNAPSHOT" (case
      # sensitive)
      def snapshot?(version)
        version.end_with?("-SNAPSHOT")
      end

      # Returns the currently deployed version of an artifact given that artifacts
      # installation directory by reading what directory the 'current' symlink
      # points to.
      # if the 'current' directory is not a symlink, a ".symlinks" file is opened and the value
      # indicated by the 'current' key is returned.
      #
      # @param  deploy_to_dir [String] the directory where an artifact is installed
      #
      # @example
      #   Chef::Artifact.get_current_deployed_version("/opt/my_deploy_dir") => "2.0.65"
      #
      # @return [String] the currently deployed version of the given artifact
      def get_current_deployed_version(deploy_to_dir)

        current_dir = ::File.join(deploy_to_dir, "current")
        if ::File.exists?(current_dir)
          if symlink?(current_dir)
            ::File.basename(readlink(current_dir))
          else
            symlinks_file = ::File.join(deploy_to_dir, ".symlinks")
            raise Exception, "error : file #{symlinks_file} doesn't exist" unless ::File.exist? symlinks_file
            YAML.load_file(symlinks_file)['current']
          end
        end
      end

      # Looks for the given data bag in the cache and if not found, will load a
      # data bag item named for the chef_environment, '_wildcard', or the old
      # 'nexus' value.
      #
      # @param  environment [String] the environment
      # @param  data_bag [String] the data bag to load
      #
      # @return [Chef::Mash] the data bag item in Mash form
      def encrypted_data_bag_for(environment, data_bag)
        @encrypted_data_bags = {} unless @encrypted_data_bags

        if encrypted_data_bags[data_bag]
          return get_from_data_bags_cache(data_bag)
        else
          data_bag_item = encrypted_data_bag_item(data_bag, environment)
          data_bag_item ||= encrypted_data_bag_item(data_bag, WILDCARD_DATABAG_ITEM)
          data_bag_item ||= encrypted_data_bag_item(data_bag, "nexus")
          data_bag_item ||= {}
          @encrypted_data_bags[data_bag] = data_bag_item
          return data_bag_item
        end
      end

      # @return [Hash]
      def encrypted_data_bags
        @encrypted_data_bags
      end

      # Loads an entry from the encrypted_data_bags class variable.
      #
      # @param data_bag [String] the data bag to find
      #
      # @return [type] [description]
      def get_from_data_bags_cache(data_bag)
        encrypted_data_bags[data_bag]
      end

      # Loads an EncryptedDataBagItem from the Chef server and
      # turns it into a Chef::Mash, giving it indifferent access. Returns
      # nil when a data bag item is not found.
      #
      # @param  data_bag [String]
      # @param  data_bag_item [String]
      #
      # @raise [Chef::Artifact::DataBagEncryptionError] when the data bag cannot be decrypted
      #   or transformed into a Mash for some reason (Chef 10 vs Chef 11 data bag changes).
      #
      # @return [Chef::Mash]
      def encrypted_data_bag_item(data_bag, data_bag_item)
        Mash.from_hash(Chef::EncryptedDataBagItem.load(data_bag, data_bag_item).to_hash)
      rescue Net::HTTPServerException => e
        nil
      rescue NoMethodError
        raise DataBagEncryptionError.new
      end

      # Create and Write content of the ".symlinks" file. This file contains a reference
      # to the reference of release version which "current" is pointing to.
      #
      # @param deploy_to_dir [String] root directory containing the ".symlinks" file.
      # @param current_version_pointing_to [String] current release version referenced by "current"
      def write_current_symlink_to(deploy_to_dir, current_version_pointing_to)
        symlinks_file = ::File.join(deploy_to_dir, ".symlinks")
        if ::File.exist?(symlinks_file)
          symlinks_content = YAML.load_file(symlinks_file)
        else
          symlinks_content = Hash.new
        end
        symlinks_content['current'] = current_version_pointing_to
        ::File.open(symlinks_file , 'w+') {|f| f.write(symlinks_content.to_yaml) }
      end
    end
  end
end
