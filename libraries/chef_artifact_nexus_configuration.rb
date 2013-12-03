class Chef
  module Artifact
    class NexusConfiguration
      class << self
        def from_data_bag
          environment = unless Chef::Config[:solo]
            Chef::Node.load(Chef::Config[:node_name]).chef_environment
          else
            nil
          end

          config = Chef::Artifact.data_bag_config_for(environment, Chef::Artifact::DATA_BAG_NEXUS)
          if config.nil? || config.empty?
            Chef::Log.debug "No Data Bag found for NexusConfiguration."
            nil
          else
            new(config['url'], config['repository'], config['username'], config['password'], config['ssl_verify'])
          end
        end
      end

      attr_accessor :url, :repository, :username, :password, :ssl_verify

      def initialize(url, repository, username=nil, password=nil, ssl_verify=true)
        @url, @repository, @username, @password = url, repository, username, password
        @ssl_verify = ssl_verify.nil? || ssl_verify
      end

      alias_method :inspect_without_masking, :inspect
      def inspect
        self.inspect_without_masking.sub(/@password=".*"/, '@password="MASKED"')
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
