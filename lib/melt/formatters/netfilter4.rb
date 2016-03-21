module Melt
  module Formatters
    module Netfilter4 # :nodoc:
      # IPv4 Netfilter implementation of a Melt Ruleset formatter.
      class Ruleset < Melt::Formatters::Netfilter::Ruleset # :nodoc:
        # Return an IPv4 Netfilter String representation of the provided +rules+ Melt::Rule with the +policy+ policy.
        def emit_ruleset(rules, policy = :block)
          super(rules.select(&:ipv4?), policy)
        end

        def filename_fragment
          ['netfilter', 'rules.v4']
        end
      end

      # IPv4 Netfilter implementation of a Melt Rulet formatter.
      class Rule < Melt::Formatters::Netfilter::Rule # :nodoc:
      end
    end
  end
end
