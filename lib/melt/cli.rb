require 'melt'
require 'thor'

module Melt
  # Cli
  class Cli < Thor
    option :formatter, default: 'Pf', desc: 'The formatter to use', aliases: :f
    desc 'generate NETWORK HOSTNAME', 'generates the configuration for HOSTNAME as described in NETWORK.'
    def generate(network, hostname)
      config = Melt::Dsl.new
      config.eval_network(network)
      rules = config.ruleset_for(hostname)
      policy = config.policy_for(hostname)

      formatter = Object.const_get("Melt::Formatters::#{options[:formatter]}").new
      puts formatter.emit_ruleset(rules, policy)
    end
  end
end
