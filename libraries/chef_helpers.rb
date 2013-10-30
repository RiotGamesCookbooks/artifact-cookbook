class Chef
  module Artifact
    module Helpers
      # A wrapper that adds debug logging for running a recipe_eval on the
      # numerous Proc attributes defined for this resource.
      #
      # @param from     [String] location where the proc is executed from
      # @param resource [Chef::Resource::ArtifactDeploy] resource being executed on
      # @param name     [Symbol] the name of the proc to execute
      #
      # @return [void]
      def execute_run_proc(from, resource, name)
        proc = resource.send(name)
        proc_name = name.to_s
        Chef::Log.debug "#{from}[run_proc::#{proc_name}] Determining whether to execute #{proc_name} proc."
        if proc
          Chef::Log.debug "#{from}[run_proc::#{proc_name}] Beginning execution of #{proc_name} proc."
          recipe_eval(&proc)
          Chef::Log.debug "#{from}[run_proc::#{proc_name}] Ending execution of #{proc_name} proc."
        else
          Chef::Log.debug "#{from}[run_proc::#{proc_name}] Skipping execution of #{proc_name} proc because it was not defined."
        end
      end
    end
  end
end
