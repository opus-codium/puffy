# frozen_string_literal: true

module Puffy
  module Formatters
    module Nftables # :nodoc:
      # Returns the rule action
      #
      # @return [String]
      def self.nftables_action(rule_or_action, ret: false)
        case rule_or_action
        when :pass      then 'accept'
        when :block     then ret ? 'return' : 'drop'
        when Puffy::Rule then nftables_action(rule_or_action.action, ret: rule_or_action.return)
        end
      end

      # Nftables implementation of a Puffy Ruleset formatter.
      class Ruleset < Puffy::Formatters::Base::Ruleset
        alias parent_emit_ruleset emit_ruleset

        # Returns a Nftables String representation of the provided +rules+ Array of Puffy::Rule.
        def emit_ruleset(rules, policy = :block)
          <<~FRAGMENT
            #!/usr/sbin/nft -f

            flush ruleset

            #{inet_filter(rules, policy)}
          FRAGMENT
        end

        def inet_filter(rules, policy)
          <<~FRAGMENT.chomp
            table inet filter {
            #{chain_input(rules.select(&:in?), policy)}
            #{chain_forward(rules.select(&:fwd?))}
            #{chain_output(rules.select(&:out?), policy)}
            }
          FRAGMENT
        end

        def chain_input(rules, policy)
          <<~FRAGMENT.chomp
            \tchain input {
            \t\ttype filter hook input priority 0;
            \t\tpolicy #{Nftables.nftables_action(policy)};
            \t\tct state {established, related} accept;
            #{parent_emit_ruleset(rules)}
            \t}
          FRAGMENT
        end

        def chain_forward(rules)
          <<~FRAGMENT.chomp
            \tchain forward {
            \t\ttype filter hook forward priority 0;
            #{parent_emit_ruleset(rules)}
            \t}
          FRAGMENT
        end

        def chain_output(rules, policy)
          <<~FRAGMENT.chomp
            \tchain output {
            \t\ttype filter hook output priority 0;
            \t\tpolicy #{Nftables.nftables_action(policy)};
            \t\tct state {established, related} accept;
            #{parent_emit_ruleset(rules)}
            \t}
          FRAGMENT
        end

        def filename_fragment
          ['nftables', 'nftables.conf']
        end
      end

      # Nftables implementation of a Puffy Rule formatter.
      class Rule < Puffy::Formatters::Base::Rule
        # Returns a Nftables String representation of the provided +rule+ Puffy::Rule.
        def emit_rule(rule)
          parts = []
          parts << emit_what(rule)
          "\t\t#{parts.flatten.compact.join(' ')};"
        end

        private

        def emit_what(rule)
          parts = []
          parts << emit_proto(rule)
          parts += emit_on(rule)
          parts += emit_from(rule)
          parts += emit_to(rule)
          parts << Nftables.nftables_action(rule)
          parts
        end

        def emit_proto(rule)
          parts = []
          if rule.proto
            proto_name = case rule.proto
                         when :icmpv6 then :'ipv6-icmp'
                         else rule.proto
                         end
            parts += ['meta', 'l4proto', proto_name]
          end
          parts
        end

        def emit_on(rule)
          parts = []
          if rule.on
            cmd = case rule.dir
                  when :in then 'iif'
                  when :out then 'oif'
                  end
            parts += ['meta', cmd, rule.on] if rule.on
          end
          parts
        end

        def emit_from(rule)
          parts = []
          parts += [rule.from_host.ipv6? ? 'ip6' : 'ip', 'saddr', emit_address(rule.from_host)] if rule.from_host
          parts += ['th', 'sport', rule.from_port] if rule.from_port
          parts
        end

        def emit_to(rule)
          parts = []
          parts += [rule.to_host.ipv6? ? 'ip6' : 'ip', 'daddr', emit_address(rule.to_host)] if rule.to_host
          parts += ['th', 'dport', rule.to_port] if rule.to_port
          parts
        end
      end
    end
  end
end
