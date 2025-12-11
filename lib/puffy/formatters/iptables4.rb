# frozen_string_literal: true

module Puffy
  module Formatters
    module Iptables4 # :nodoc:
      # IPv4 Iptables implementation of a Puffy Ruleset formatter.
      class Ruleset < Puffy::Formatters::Iptables::Ruleset # :nodoc:
        # Return an IPv4 Iptables String representation of the provided +rules+ Puffy::Rule with the +policies+ policies.
        def emit_ruleset(rules, policies)
          super(rules.select(&:ipv4?), policies)
        end

        def filename_fragment
          ['iptables', 'rules.v4']
        end
      end

      # IPv4 Iptables implementation of a Puffy Rulet formatter.
      class Rule < Puffy::Formatters::Iptables::Rule # :nodoc:
      end
    end
  end
end
