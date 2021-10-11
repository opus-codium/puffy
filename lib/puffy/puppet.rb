# frozen_string_literal: true

require 'fileutils'

module Puffy
  # Manage nodes rulesets as a tree of rules to serve via Puppet
  class Puppet
    # Setup an environment to store firewall rules to disk
    #
    # @param path [String] Root directory of the tree of firewall rules
    # @param parser [Puffy::Parser] A parser with nodes and rules
    def initialize(path, parser)
      @path = path
      @parser = parser

      @formatters = [
        Puffy::Formatters::Pf::Ruleset.new,
        Puffy::Formatters::Netfilter4::Ruleset.new,
        Puffy::Formatters::Netfilter6::Ruleset.new,
      ]
    end

    # Saves rules to disk
    #
    # @return [void]
    def save
      each_fragment do |fragment_name, fragment_content|
        FileUtils.mkdir_p(File.dirname(fragment_name))

        next unless fragment_changed?(fragment_name, fragment_content)

        File.open(fragment_name, 'w') do |f|
          f.write(fragment_content)
        end
      end
    end

    # Show differences between saved and generated rules
    #
    # @return [void]
    def diff
      each_fragment do |fragment_name, fragment_content|
        human_fragment_name = fragment_name.delete_prefix(@path).delete_prefix('/')
        IO.popen("diff -u1 -N --unidirectional-new-file --ignore-matching-lines='^#' --label a/#{human_fragment_name} #{fragment_name} --label b/#{human_fragment_name} -", 'r+') do |io|
          io.write(fragment_content)
          io.close_write
          out = io.read
          $stdout.write out
        end
      end
    end

    private

    def each_fragment
      @parser.nodes.each do |hostname|
        rules = @parser.ruleset_for(hostname)
        policy = @parser.policy_for(hostname)

        @formatters.each do |formatter|
          filename = File.join(@path, hostname, formatter.filename_fragment)
          yield filename, formatter.emit_ruleset(rules, policy)
        end
      end
    end

    def fragment_changed?(fragment_name, fragment_content)
      return true unless File.exist?(fragment_name)

      File.read(fragment_name).split("\n").reject { |l| l =~ /^#/ } != fragment_content.split("\n").reject { |l| l =~ /^#/ }
    end
  end
end
