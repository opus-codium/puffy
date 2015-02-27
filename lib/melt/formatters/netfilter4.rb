module Melt
  module Formatters
    # IPv4 Netfilter implementation of a Melt formatter.
    class Netfilter4 < Netfilter
      # Return an IPv4 Netfilter String representation of the provided +rules+ Rule with the +policy+ policy.
      def emit_ruleset(rules, policy = :block)
        super(rules.select { |x| x.ipv4? }, policy)
      end
    end
  end
end
