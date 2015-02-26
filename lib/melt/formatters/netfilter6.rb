module Melt
  module Formatters
    # IPv6 Netfilter implementation of a Melt formatter.
    class Netfilter6 < Netfilter
      # Return an IPv6 Netfilter String representation of the provided +rules+ Rule.
      def emit_ruleset(rules)
        super(rules.select { |x| x.ipv6? })
      end
    end
  end
end
