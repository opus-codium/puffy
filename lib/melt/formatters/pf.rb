module Melt
  module Formatters
    # Pf implementation of a Melt formatter.
    class Pf < Base
      # Returns a Pf String representation of the provided +rule+ Melt::Rule.
      def emit_rule(rule)
        parts = []
        parts << rule.action
        parts << 'return' if rule.action == :block && rule.return
        parts << rule.dir if rule.dir
        parts << 'quick' unless rule.no_quick
        parts << "on #{rule.on.gsub('!', '! ')}" if rule.on
        parts << rule.af if rule.af
        parts << "proto #{rule.proto}" if rule.proto
        if rule.src_host || rule.src_port
          parts << 'from'
          parts << emit_address(rule.src_host) if rule.src_host
          parts << "port #{rule.src_port}" if rule.src_port
        end
        if rule.dst_host || rule.dst_port
          parts << 'to'
          parts << emit_address(rule.dst_host) if rule.dst_host
          parts << "port #{rule.dst_port}" if rule.dst_port
        end
        if rule.rdr?
          parts << if @loopback_addresses.include?(rule.rdr_to_host)
                     "divert-to #{emit_address(rule.rdr_to_host, loopback_address(rule.af))}"
                   else
                     "rdr-to #{emit_address(rule.rdr_to_host)}"
                   end
          parts << "port #{rule.rdr_to_port}" if rule.rdr_to_port
        end
        parts << "nat-to #{emit_address(rule.nat_to)}" if rule.nat_to
        parts.join(' ')
      end

      # Returns a Pf String representation of the provided +rules+ Array of Melt::Rule.
      def emit_ruleset(rules, policy = :block)
        parts = []

        parts << 'match in all scrub (no-df)'
        parts << 'set skip on lo'
        parts << super([Rule.new(action: policy, return: true, no_quick: true)])

        parts << super([Rule.new(action: :block, return: true, dir: :in, on: '!lo0', proto: :tcp, to: { port: '6000:6010' }, no_quick: true)])

        parts << super(rules.select(&:nat?))
        parts << super(rules.select(&:rdr?))
        parts << super(rules.select(&:filter?))

        parts.reject(&:empty?).join("\n")
      end

      protected

      # Return a valid PF representation of +host+.
      def emit_address(host, if_unspecified = 'any')
        if host
          super(host)
        else
          if_unspecified
        end
      end
    end
  end
end
