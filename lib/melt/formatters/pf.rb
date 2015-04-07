module Melt
  module Formatters
    # Pf implementation of a Melt formatter.
    class Pf < Base
      # Returns a Pf String representation of the provided +rule+ Rule.
      def emit_rule(rule)
        parts = []
        parts << rule.action
        if rule.action == :block && rule.return then
          parts << 'return'
        end
        parts << rule.dir if rule.dir
        parts << 'quick' unless rule.no_quick
        parts << "on #{rule.on.gsub('!', '! ')}" if rule.on
        parts << rule.af if rule.af
        parts << "proto #{rule.proto}" if rule.proto
        if rule.from && (rule.from[:host] || rule.from[:port]) then
          parts << 'from'
          parts << emit_address(rule.from[:host]) if rule.from[:host]
          parts << "port #{rule.src_port}" if rule.src_port
        end
        if rule.to && (rule.to[:host] || rule.to[:port]) then
          parts << 'to'
          parts << emit_address(rule.to[:host]) if rule.to[:host]
          parts << "port #{rule.dst_port}" if rule.dst_port
        end
        if rule.rdr? then
          if @loopback_addresses.include?(rule.rdr_to[:host]) then
            parts << "divert-to #{emit_address(rule.rdr_to[:host], loopback_address(rule.af))}"
            parts << "port #{rule.rdr_to_port}" if rule.rdr_to_port
          else
            parts << "rdr-to #{emit_address(rule.rdr_to[:host])}"
            parts << "port #{rule.rdr_to_port}" if rule.rdr_to_port
          end
        end
        if rule.nat_to then
          parts << "nat-to #{emit_address(rule.nat_to)}"
        end
        parts.join(' ')
      end

      # Returns a Pf String representation of the provided +rules+ Array of Rule.
      def emit_ruleset(rules, policy = :block)
        parts = []

        parts << 'match in all scrub (no-df)'
        parts << 'set skip on lo'
        parts << super([Rule.new(action: policy, return: true, no_quick: true)])

        parts << super([Rule.new(action: :block, return: true, dir: :in, on: '!lo0', proto: :tcp, to: { port: '6000:6010' }, no_quick: true)])

        parts << super(rules.select { |r| r.nat? })
        parts << super(rules.select { |r| r.rdr? })
        parts << super(rules.select { |r| r.filter? })

        parts.reject { |s| s.empty? }.join("\n")
      end

    protected
      # Return a valid PF representation of +host+.
      def emit_address(host, if_unspecified = 'any')
        if host then
          super(host)
        else
          if_unspecified
        end
      end
    end
  end
end
