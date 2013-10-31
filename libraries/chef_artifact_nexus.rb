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
      # @param  coordinates [String] a colon-separated Maven identifier string that represents the artifact
      #
      # @example
      #   nexus.get_actual_version("com.myartifact:my-artifact:tgz:latest") => "2.0.5"
      #   nexus.get_actual_version("com.myartifact:my-artifact:tgz:1.0.1")  => "1.0.1"
      #
      # @return [String] the version number that latest resolves to or the passed in value
      def get_actual_version(coordinates)
        artifact = NexusCli::Artifact.new(coordinates)
        if Chef::Artifact.latest?(artifact.version)
          REXML::Document.new(remote.get_artifact_info(coordinates)).elements["//version"].text
        else
          artifact.version
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
      # @param  coordinates [String] a colon-separated Maven identifier that represents the artifact
      #
      # @return [String] the SHA1 entry for the artifact
      def get_artifact_sha(coordinates)
        REXML::Document.new(remote.get_artifact_info(coordinates)).elements["//sha1"].text
      end
    end
  end
end
