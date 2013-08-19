require 'nexus_cli'

class Chef
  module Artifact
    class NexusConfiguration
      class << self
        def default
          config = data_bag_config_for(node, Chef::Artifact::DATA_BAG)
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

      def remote_for
        NexusCli::RemoteFactory.create(to_hash, ssl_verify)
      end
    end
  end
end
