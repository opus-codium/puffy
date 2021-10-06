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
        usage   'melt [options] <command>'
        summary 'Network firewall rules made easy!'

        description <<~DESCRIPTION
          Generate firewall rules for multiple nodes from a single network
          specification file.
        DESCRIPTION

        flag :h, :help, 'Show help for this command' do |_value, cmd|
          puts cmd.help
          exit 0
        end

        run do |_opts, _args, cmd|
          puts cmd.help
          exit 0
        end
      end

      @main.define_command do
        name    'generate'
        usage   'generate [options] <network> <hostname>'
        summary 'Generate the firewall configuration for a node'

        description <<~DESCRIPTION
          Generate the firewall configuration for the node "hostname" for which
          the configuration is described in the "network" specification file.
        DESCRIPTION

        required :f, :formatter, 'The formatter to use', default: 'Pf'

        param('network')
        param('hostname')

        run do |opts, args|
          parser = cli.load_network(args[:network])
          rules = parser.ruleset_for(args[:hostname])
          policy = parser.policy_for(args[:hostname])

          formatter = Object.const_get("Melt::Formatters::#{opts[:formatter]}::Ruleset").new
          puts formatter.emit_ruleset(rules, policy)
        end
      end

      puppet = @main.define_command do
        name    'puppet'
        usage   'puppet [options] <subcommand>'
        summary 'Run puppet actions'

        description <<~DESCRIPTION
          Manage a directory of firewall configurations files suitable for Puppet.
        DESCRIPTION

        required :o, :output, 'Base directory for network firewall rules', default: '.'

        run do |_opts, _args, cmd|
          puts cmd.help
          exit 0
        end
      end

      puppet.define_command do
        name    'diff'
        usage   'diff [options] <network>'
        summary 'Show differences between network specification and firewall rules'

        description <<~DESCRIPTION
          Show the changes that would be introduced by running `melt puppet
          generate` with the current "network" specification file.
        DESCRIPTION

        param('network')

        run do |opts, args|
          parser = cli.load_network(args[:network])
          puppet = Melt::Puppet.new(opts[:output], parser)
          puppet.diff
        end
      end

      puppet.define_command do
        name    'generate'
        usage   'generate [options] <network>'
        summary 'Generate network firewall rules according to network specification'

        description <<~DESCRIPTION
          Generate a tree of configuration files suitable for all supported
          firewalls for all the nodes described in the "network" specification
          file.
        DESCRIPTION

        param('network')

        run do |opts, args|
          parser = cli.load_network(args[:network])
          puppet = Melt::Puppet.new(opts[:output], parser)
          puppet.save
        end
      end

      help_command = Cri::Command.new_basic_help.modify do
        summary 'Show help for a command'
      end

      @main.add_command(help_command)
    end

    def load_network(filename)
      parser = Melt::Parser.new
      parser.parse_file(filename)
      parser
    end

    def execute(argv)
      @main.run(argv)
    end
  end
end
