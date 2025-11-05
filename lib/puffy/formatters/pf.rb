# frozen_string_literal: true

module Puffy
  module Formatters
    module Pf # :nodoc:
      # Pf implementation of a Puffy Ruleset formatter.
      class Ruleset < Puffy::Formatters::Base::Ruleset # :nodoc:
        # Returns a Pf String representation of the provided +rules+ Array of Puffy::Rule.
        def emit_ruleset(rules, policy = :block)
          parts = []

          parts << emit_header(policy)

          parts << super(rules.select(&:nat?))
          parts << super(rules.select(&:rdr?))
          parts << super(rules.select(&:filter?))

          ruleset = parts.reject(&:empty?).join("\n")
          "#{ruleset}\n"
        end

        def filename_fragment
          ['pf', 'pf.conf']
        end

        def emit_header(policy)
          parts = super()
          parts << 'match in all scrub (no-df)'
          parts << 'set skip on lo'
          parts << @rule_formatter.emit_rule(Puffy::Rule.new(action: policy, dir: :in, no_quick: true))
          parts << @rule_formatter.emit_rule(Puffy::Rule.new(action: policy, dir: :out, no_quick: true))
          parts
        end
      end

      # Pf implementation of a Puffy Rule formatter.
      class Rule < Puffy::Formatters::Base::Rule # :nodoc:
        # Returns a Pf String representation of the provided +rule+ Puffy::Rule.
        def emit_rule(rule)
          parts = []
          parts << emit_action(rule)
          parts << emit_direction(rule)
          parts << emit_quick(rule)
          parts << emit_on(rule)
          parts << emit_what(rule)
          parts.flatten.compact.join(' ')
        end

        private

        def emit_action(rule)
          parts = [rule.action]
          parts << 'return' if rule.action == :block && rule.return
          parts
        end

        def emit_direction(rule)
          if rule.fwd? && rule.in
            'in'
          elsif rule.fwd? && rule.out
            'out'
          else
            rule.dir
          end
        end

        def emit_quick(rule)
          'quick' unless rule.no_quick
        end

        def emit_on(rule)
          if rule.on
            "on #{rule.on.gsub('!', '! ')}"
          elsif rule.fwd? && rule.in
            "on #{rule.in}"
          elsif rule.fwd? && rule.out
            "on #{rule.out}"
          end
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
          emit_endpoint_specification('from', rule.from_host, rule.from_port) if rule.from_host || rule.from_port
        end

        def emit_to(rule)
          emit_endpoint_specification('to', rule.to_host, rule.to_port) if rule.to_host || rule.to_port
        end

        def emit_endpoint_specification(keyword, host, port)
          parts = [keyword]
          parts << emit_address(host)
          parts << "port #{emit_port(port)}" if port
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
          return unless rule.rdr?

          keyword = rdr_to_keyword(rule)
          destination = rule.rdr_to_host || loopback_address(rule.af)
          raise 'Unspecified address family' if destination.nil?

          emit_endpoint_specification(keyword, destination, rule.rdr_to_port)
        end

        def rdr_to_keyword(rule)
          if Puffy::Formatters::Base.loopback_addresses.include?(rule.rdr_to_host)
            'divert-to'
          else
            'rdr-to'
          end
        end

        def emit_nat_to(rule)
          "nat-to #{emit_address(rule.nat_to)}" if rule.nat_to
        end
      end
    end
  end
end
