# frozen_string_literal: true

module Puffy
  module Formatters
    module Netfilter4 # :nodoc:
      # IPv4 Netfilter implementation of a Puffy Ruleset formatter.
      class Ruleset < Puffy::Formatters::Netfilter::Ruleset # :nodoc:
        # Return an IPv4 Netfilter String representation of the provided +rules+ Puffy::Rule with the +policy+ policy.
        def emit_ruleset(rules, policy = :block)
          super(rules.select(&:ipv4?), policy)
        end

        def filename_fragment
          ['netfilter', 'rules.v4']
        end
      end

      # IPv4 Netfilter implementation of a Puffy Rulet formatter.
      class Rule < Puffy::Formatters::Netfilter::Rule # :nodoc:
      end
    end
  end
end
