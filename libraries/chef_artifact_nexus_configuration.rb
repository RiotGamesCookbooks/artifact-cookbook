class Chef
  module Artifact
    class NexusConfiguration
      class << self
        def default
          config = Chef::Artifact.data_bag_config_for(nil, Chef::Artifact::DATA_BAG)
          new(config[:url], config[:repository], config[:username], config[:password])
        end
      end

      attr_accessor :url, :repository, :username, :password, :ssl_verify

      def initialize(url, repository, username, password, ssl_verify=true)
        @url, @repository, @username, @password, @ssl_verify = url, repository, username, password, ssl_verify
      end

      def to_hash
        { 
          url: url,
          repository: repository,
          username: username,
          password: password
        }
      end
    end
  end
end
