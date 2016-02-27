require 'fileutils'

module Melt
  # Save host ruleset as a tree of rules to serve via Puppet
  class Puppet
    def initialize(path, dsl)
      @path = path
      @dsl = dsl

      @formatters = [
        Melt::Formatters::Pf.new,
        Melt::Formatters::Netfilter4.new,
        Melt::Formatters::Netfilter6.new
      ]
    end

    def save
      each_fragment do |fragment_name, fragment_content|
        FileUtils.mkdir_p(File.dirname(fragment_name))
        File.open(fragment_name, 'w') do |f|
          f.write(fragment_content)
        end
      end
    end

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
  end
end
