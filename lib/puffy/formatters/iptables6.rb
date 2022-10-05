# frozen_string_literal: true

module Puffy
  module Formatters
    module Netfilter6 # :nodoc:
      # IPv6 Iptables implementation of a Puffy Ruleset formatter.
      class Ruleset < Puffy::Formatters::Iptables::Ruleset # :nodoc:
        # Return an IPv6 Iptables String representation of the provided +rules+ Puffy::Rule with the +policy+ policy.
        def emit_ruleset(rules, policy = :block)
          super(rules.select(&:ipv6?), policy)
        end

        def filename_fragment
          ['iptables', 'rules.v6']
        end
      end

      # IPv6 Iptables implementation of a Puffy Rule formatter.
      class Rule < Puffy::Formatters::Iptables::Rule # :nodoc:
      end
    end
  end
end
