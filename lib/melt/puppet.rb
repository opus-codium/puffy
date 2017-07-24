# frozen_string_literal: true

require 'fileutils'

module Melt
  # Manage hosts rulesets as a tree of rules to serve via Puppet
  class Puppet
    # Setup an environment to store firewall rules to disk
    #
    # @param path [String] Root directory of the tree of firewall rules
    # @param dsl [Melt::Dsl] Description of hosts and rules as a Melt::Dsl
    def initialize(path, dsl)
      @path = path
      @dsl = dsl

      @formatters = [
        Melt::Formatters::Pf::Ruleset.new,
        Melt::Formatters::Netfilter4::Ruleset.new,
        Melt::Formatters::Netfilter6::Ruleset.new
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
        IO.popen("diff -u -N --unidirectional-new-file --ignore-matching-lines='^#' --label a/#{fragment_name} --from-file #{fragment_name} --label b/#{fragment_name} -", 'r+') do |io|
          io.write(fragment_content)
          io.close_write
          out = io.read
          $stdout.write out
        end
      end
    end

    private

    def each_fragment
      @dsl.hosts.each do |host|
        rules = @dsl.ruleset_for(host)
        policy = @dsl.policy_for(host)

        @formatters.each do |formatter|
          filename = File.join(host, formatter.filename_fragment)
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
