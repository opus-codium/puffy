# frozen_string_literal: true

module Puffy
  module Formatters
    module Iptables6 # :nodoc:
      # IPv6 Iptables implementation of a Puffy Ruleset formatter.
      class Ruleset < Puffy::Formatters::Iptables::Ruleset # :nodoc:
        # Return an IPv6 Iptables String representation of the provided +rules+ Puffy::Rule with the +policies+ policies.
        def emit_ruleset(rules, policies)
          super(rules.select(&:ipv6?), policies)
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
