# frozen_string_literal: true

require 'cri'
require 'melt'
require 'fileutils'

module Melt
  # Command-line processing
  class Cli
    def initialize
      @main = Cri::Command.define do
        name    'melt'
        usage   'melt <command> [options]'
        summary 'Network firewall rules made easy!'
      end

      @main.define_command do
        name        'generate'
        usage       'generate <network> <hostname>'
        summary     'Generate the firewall configuration for a node.'

        required :f, :formatter, 'The formatter to use', default: 'Pf'

        param('network')
        param('hostname')

        run do |opts, args|
          config = Melt::Dsl.new
          config.eval_network(args[:network])
          rules = config.ruleset_for(args[:hostname])
          policy = config.policy_for(args[:hostname])

          formatter = Object.const_get("Melt::Formatters::#{opts[:formatter]}::Ruleset").new
          puts formatter.emit_ruleset(rules, policy)
        end
      end

      puppet = @main.define_command do
        name    'puppet'
        usage   'puppet subcommand [options]'
        summary 'Run puppet actions.'
      end

      puppet.define_command do
        name    'diff'
        usage   'diff network'
        summary 'Show differences between network specification and firewall rules.'

        param('network')

        run do |_opts, args|
          config = Melt::Dsl.new
          config.eval_network(args[:network])
          pu = Melt::Puppet.new('.', config)
          pu.diff
        end
      end

      puppet.define_command do
        name    'generate'
        usage   'generate network'
        summary 'Generate network firewall rules according to network specification.'

        param('network')

        run do |_opts, args|
          config = Melt::Dsl.new
          config.eval_network(args[:network])
          pu = Melt::Puppet.new('.', config)
          pu.save
        end
      end

      @main.add_command Cri::Command.new_basic_help
    end

    def execute(argv)
      @main.run(argv)
    end
  end
end
