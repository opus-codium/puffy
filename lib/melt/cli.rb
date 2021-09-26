# frozen_string_literal: true

require 'cri'
require 'melt'
require 'fileutils'

module Melt
  # Command-line processing
  class Cli
    def initialize
      cli = self

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
          parser = cli.load_config(args[:network])
          rules = parser.ruleset_for(args[:hostname])
          policy = parser.policy_for(args[:hostname])

          formatter = Object.const_get("Melt::Formatters::#{opts[:formatter]}::Ruleset").new
          puts formatter.emit_ruleset(rules, policy)
        end
      end

      puppet = @main.define_command do
        name    'puppet'
        usage   'puppet subcommand [options]'
        summary 'Run puppet actions.'

        required :o, :output, 'Base directory for network firewall rules', default: '.'
      end

      puppet.define_command do
        name    'diff'
        usage   'diff network'
        summary 'Show differences between network specification and firewall rules.'

        param('network')

        run do |opts, args|
          parser = cli.load_config(args[:network])
          puppet = Melt::Puppet.new(opts[:output], parser)
          puppet.diff
        end
      end

      puppet.define_command do
        name    'generate'
        usage   'generate network'
        summary 'Generate network firewall rules according to network specification.'

        param('network')

        run do |opts, args|
          parser = cli.load_config(args[:network])
          puppet = Melt::Puppet.new(opts[:output], parser)
          puppet.save
        end
      end

      @main.add_command Cri::Command.new_basic_help
    end

    def load_config(filename)
      parser = Melt::Parser.new
      parser.parse_file(filename)
      parser
    end

    def execute(argv)
      @main.run(argv)
    end
  end
end
