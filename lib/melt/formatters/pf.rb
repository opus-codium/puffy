module Melt
  module Formatters
    # Pf implementation of a Melt formatter.
    class Pf < Base
      # Returns a Pf String representation of the provided +rule+ Melt::Rule.
      def emit_rule(rule)
        parts = []
        parts << emit_action(rule)
        parts << emit_direction(rule)
        parts << emit_quick(rule)
        parts << emit_on(rule)
        parts << emit_what(rule)
        parts.flatten.compact.join(' ')
      end

      # Returns a Pf String representation of the provided +rules+ Array of Melt::Rule.
      def emit_ruleset(rules, policy = :block)
        parts = []

        parts << emit_header(policy)

        parts << super(rules.select(&:nat?))
        parts << super(rules.select(&:rdr?))
        parts << super(rules.select(&:filter?))

        parts.reject(&:empty?).join("\n") + "\n"
      end

      def filename_fragment
        ['pf', 'pf.conf']
      end

      private

      def emit_header(policy)
        parts = ['match in all scrub (no-df)']
        parts << 'set skip on lo'
        parts << emit_rule(Rule.new(action: policy, dir: :in, no_quick: true))
        parts << emit_rule(Rule.new(action: policy, dir: :out, no_quick: true))
        parts
      end

      def emit_action(rule)
        parts = [rule.action]
        parts << 'return' if rule.action == :block && rule.return
        parts
      end

      def emit_direction(rule)
        rule.dir if rule.dir
      end

      def emit_quick(rule)
        'quick' unless rule.no_quick
      end

      def emit_on(rule)
        "on #{rule.on.gsub('!', '! ')}" if rule.on
      end

      def emit_what(rule)
        parts = [emit_af(rule)]
        parts << emit_proto(rule)
        parts << emit_from(rule)
        parts << emit_to(rule)
        parts << emit_rdr_to(rule)
        parts << emit_nat_to(rule)

        parts.flatten.compact.empty? ? 'all' : parts
      end

      def emit_af(rule)
        if rule.implicit_ipv4? || rule.implicit_ipv6?
          nil
        elsif rule.ipv4? || rule.ipv6?
          rule.af
        end
      end

      def emit_proto(rule)
        "proto #{rule.proto}" if rule.proto
      end

      def emit_from(rule)
        emit_endpoint_specification('from', rule.src_host, rule.src_port) if rule.src_host || rule.src_port
      end

      def emit_to(rule)
        emit_endpoint_specification('to', rule.dst_host, rule.dst_port) if rule.dst_host || rule.dst_port
      end

      def emit_endpoint_specification(keyword, host, port)
        parts = [keyword]
        parts << emit_address(host)
        parts << "port #{port}" if port
        parts
      end

      # Return a valid PF representation of +host+.
      def emit_address(host, if_unspecified = 'any')
        if host
          super(host)
        else
          if_unspecified
        end
      end

      def emit_rdr_to(rule)
        if rule.rdr?
          keyword = @loopback_addresses.include?(rule.rdr_to_host) ? 'divert-to' : 'rdr-to'
          destination = rule.rdr_to_host || loopback_address(rule.af)
          raise 'Unspecified address family' if destination.nil?
          emit_endpoint_specification(keyword, destination, rule.rdr_to_port)
        end
      end

      def emit_nat_to(rule)
        "nat-to #{emit_address(rule.nat_to)}" if rule.nat_to
      end
    end
  end
end
