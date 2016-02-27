require 'melt'
require 'thor'
require 'fileutils'

module Melt
  module Cli
    class Puppet < Thor # :nodoc:
      desc 'generate NETWORK', 'generate the configuration for NETWORK to serve using Puppet'
      def generate(network)
        config = Melt::Dsl.new
        config.eval_network(network)
        pu = Melt::Puppet.new('.', config)
        pu.save
      end

      desc 'diff NETWORK', 'show differences between the files on disk and those that would be generated for NETWORK'
      def diff(network)
        config = Melt::Dsl.new
        config.eval_network(network)
        pu = Melt::Puppet.new('.', config)
        pu.diff
      end
    end

    class Main < Thor # :nodoc:
      desc 'generate NETWORK HOSTNAME', 'generates the configuration for HOSTNAME as described in NETWORK.'
      option :formatter, default: 'Pf', desc: 'The formatter to use', aliases: :f
      def generate(network, hostname)
        config = Melt::Dsl.new
        config.eval_network(network)
        rules = config.ruleset_for(hostname)
        policy = config.policy_for(hostname)

        formatter = Object.const_get("Melt::Formatters::#{options[:formatter]}").new
        puts formatter.emit_ruleset(rules, policy)
      end

      desc 'puppet SUBCOMMAND ...ARGS', 'puppet actions'
      subcommand 'puppet', Melt::Cli::Puppet
    end
  end
end
