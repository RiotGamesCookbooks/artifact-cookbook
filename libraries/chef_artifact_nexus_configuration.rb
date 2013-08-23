class Chef
  module Artifact
    class NexusConfiguration
      class << self
        def from_data_bag
          config = Chef::Artifact.data_bag_config_for(nil, Chef::Artifact::DATA_BAG_NEXUS)
          if config.nil? || config.empty?
            Chef::Log.debug "No Data Bag found for NexusConfiguration."
            nil
          else
            new(config['url'], config['repository'], config['username'], config['password'])
          end
        end
      end

      attr_accessor :url, :repository, :username, :password, :ssl_verify

      def initialize(url, repository, username=nil, password=nil, ssl_verify=true)
        @url, @repository, @username, @password, @ssl_verify = url, repository, username, password, ssl_verify
      end

      def to_hash
        { 
          'url' => url,
          'repository' => repository,
          'username' => username,
          'password' => password
        }
      end
    end
  end
end
