module Melt
  module Formatters
    module Netfilter6 # :nodoc:
      # IPv6 Netfilter implementation of a Melt Ruleset formatter.
      class Ruleset < Melt::Formatters::Netfilter::Ruleset
        # Return an IPv6 Netfilter String representation of the provided +rules+ Melt::Rule with the +policy+ policy.
        def emit_ruleset(rules, policy = :block)
          super(rules.select(&:ipv6?), policy)
        end

        def filename_fragment
          ['netfilter', 'rules.v6']
        end
      end

      # IPv6 Netfilter implementation of a Melt Rule formatter.
      class Rule < Melt::Formatters::Netfilter::Rule
      end
    end
  end
end
