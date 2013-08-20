require 'rexml/document'

class Chef
  module Artifact
    class Nexus

      attr_reader :node, :nexus_configuration

      def initialize(node, nexus_configuration)
        require 'nexus_cli'
        @node, @nexus_configuration = node, nexus_configuration
      end

      def remote
        @_remote ||= NexusCli::RemoteFactory.create(nexus_configuration.to_hash, nexus_configuration.ssl_verify)
      end

      # Uses the provided parameters to make a call to the data bag
      # configured Nexus server to have the server tell us what the
      # actual version number is when 'latest' is given.
      #
      # @param  artifact_location [String] a colon-separated Maven identifier string that represents the artifact
      #
      # @example
      #   Chef::Artifact.get_actual_version("com.myartifact:my-artifact:latest:tgz") => "2.0.5"
      #   Chef::Artifact.get_actual_version("com.myartifact:my-artifact:1.0.1:tgz")  => "1.0.1"
      #
      # @return [String] the version number that latest resolves to or the passed in value
      def get_actual_version(artifact_location)
        version = artifact_location.split(':')[2]
        if Chef::Artifact.latest?(version)
          REXML::Document.new(remote.get_artifact_info(artifact_location)).elements["//version"].text
        else
          version
        end
      end

      # Downloads a file to disk from the configured Nexus server.
      # 
      # @param  source [String] a colon-separated Maven identified string that represents the artifact
      # @param  destination_dir [String] a path to download the artifact to
      #
      # @return [Hash] writes a file to disk and returns a Hash with
      # information about that file. See NexusCli::ArtifactActions#pull_artifact.
      def retrieve_from_nexus(source, destination_dir)
        remote.pull_artifact(source, destination_dir)
      end

      # Makes a call to Nexus and parses the returned XML to return
      # the Nexus Server's stored SHA1 checksum for the given artifact.
      #
      # @param  artifact_location [String] a colon-separated Maven identifier that represents the artifact
      #
      # @return [String] the SHA1 entry for the artifact
      def get_artifact_sha(artifact_location)
        REXML::Document.new(remote.get_artifact_info(artifact_location)).elements["//sha1"].text
      end
    end
  end
end
