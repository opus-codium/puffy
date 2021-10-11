# frozen_string_literal: true

module Puffy
  module Formatters
    module Netfilter # :nodoc:
      # Returns the target to jump to
      #
      # @return [String]
      def self.iptables_action(rule_or_action, ret: false)
        case rule_or_action
        when :pass      then 'ACCEPT'
        when :log       then 'LOG'
        when :block     then ret ? 'RETURN' : 'DROP'
        when Puffy::Rule then iptables_action(rule_or_action.action, ret: rule_or_action.return)
        end
      end

      # Netfilter implementation of a Puffy Ruleset formatter.
      class Ruleset < Puffy::Formatters::Base::Ruleset # :nodoc:
        def self.known_conntrack_helpers
          {
            21   => 'ftp',
            69   => 'tftp',
            194  => 'irc',
            6566 => 'sane',
            5060 => 'sip',
          }
        end

        # Returns a Netfilter String representation of the provided +rules+ Array of Puffy::Rule with the +policy+ policy.
        def emit_ruleset(rules, policy = :block)
          parts = []
          parts << emit_header
          parts << raw_ruleset(raw_rules(rules))
          parts << nat_ruleset(nat_rules(rules))
          parts << filter_ruleset(filter_rules(rules), policy)
          ruleset = parts.flatten.compact.join("\n")
          "#{ruleset}\n"
        end

        private

        def raw_ruleset(rules)
          return unless rules.any?

          parts = ['*raw']
          parts << emit_chain_policies(prerouting: :pass, output: :pass)
          parts << rules.map { |rule| @rule_formatter.emit_ct_rule(rule) }.uniq
          parts << 'COMMIT'
          parts
        end

        def nat_ruleset(rules)
          return unless rules.any?

          parts = ['*nat']
          parts << emit_chain_policies(prerouting: :pass, input: :pass, output: :pass, postrouting: :pass)
          parts << rules.select(&:rdr?).map { |rule| @rule_formatter.emit_rule(rule) }
          parts << rules.select(&:nat?).map { |rule| @rule_formatter.emit_rule(rule) }
          parts << 'COMMIT'
          parts
        end

        def filter_ruleset(rules, policy)
          return unless rules.any?

          parts = ['*filter']
          parts << emit_chain_policies(input: policy, forward: policy, output: policy)
          parts << input_filter_ruleset(rules)
          parts << forward_filter_ruleset(rules)
          parts << output_filter_rulset(rules)
          parts << 'COMMIT'
          parts
        end

        def emit_chain_policies(policies)
          policies.map { |chain, action| ":#{chain.upcase} #{Puffy::Formatters::Netfilter.iptables_action(action)} [0:0]" }
        end

        def input_filter_ruleset(rules)
          parts = ['-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT']
          parts << input_filter_rules(rules).map { |rule| @rule_formatter.emit_rule(rule) }
        end

        def forward_filter_ruleset(rules)
          parts = ['-A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT']
          parts << rules.select(&:fwd?).map { |rule| @rule_formatter.emit_rule(rule) }
          parts << rules.select { |r| r.rdr? && !Puffy::Formatters::Base.loopback_addresses.include?(r.rdr_to_host) }.map { |rule| @rule_formatter.emit_rule(Puffy::Rule.fwd_rule(rule)) }
        end

        def output_filter_rulset(rules)
          parts = ['-A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT']
          parts << output_filter_rules(rules).map { |rule| @rule_formatter.emit_rule(rule) }
        end

        def raw_rules(rules)
          rules.select { |r| r.action == :pass && Ruleset.known_conntrack_helpers.include?(r.to_port) }
        end

        def nat_rules(rules)
          rules.select { |r| r.nat? || r.rdr? }
        end

        def filter_rules(rules)
          rules.select { |r| %i[pass block log].include?(r.action) }
        end

        def input_filter_rules(rules)
          rules.select { |r| r.filter? && r.in? }
        end

        def output_filter_rules(rules)
          rules.select { |r| r.filter? && r.out? }
        end
      end

      # Netfilter implementation of a Puffy Rule formatter.
      class Rule < Puffy::Formatters::Base::Rule # :nodoc:
        # Returns a Netfilter String representation of the provided +rule+ Puffy::Rule.
        def emit_rule(rule)
          if rule.nat?
            emit_postrouting_rule(rule)
          elsif rule.rdr?
            emit_prerouting_rule(rule)
          else
            emit_filter_rule(rule)
          end
        end

        def emit_ct_rule(rule)
          parts = ['-A PREROUTING']
          parts << emit_if(rule)
          parts << emit_proto(rule)
          parts << emit_src_port(rule)
          parts << emit_dst_port(rule)
          parts << '-j CT'
          parts << "--helper #{Ruleset.known_conntrack_helpers[rule.to_port]}"
          pp_rule(parts)
        end

        def emit_postrouting_rule(rule)
          "-A POSTROUTING -o #{rule.on} -j MASQUERADE"
        end

        def emit_prerouting_rule(rule)
          parts = ['-A PREROUTING']
          parts << emit_on(rule)
          parts << emit_proto(rule)
          parts << emit_src(rule)
          parts << emit_dst(rule)
          parts << emit_redirect_or_dnat(rule)
          pp_rule(parts)
        end

        def emit_filter_rule(rule)
          iptables_direction = { in: 'INPUT', out: 'OUTPUT', fwd: 'FORWARD' }
          parts = ["-A #{iptables_direction[rule.dir]}"]
          parts << '-m conntrack --ctstate NEW' if %i[tcp udp].include?(rule.proto)
          parts << emit_if(rule)
          parts << emit_proto(rule)
          parts << emit_src(rule)
          parts << emit_dst(rule)
          parts << emit_jump(rule)
          pp_rule(parts)
        end

        def emit_if(rule)
          if rule.on
            emit_on(rule)
          else
            emit_in_out(rule)
          end
        end

        def emit_on(rule)
          on_direction_flag = { in: '-i', out: '-o' }

          return unless rule.on || rule.dir

          matches = /(!)?(.*)/.match(rule.on)
          [matches[1], on_direction_flag[rule.dir], matches[2]].compact
        end

        def emit_in_out(rule)
          parts = []
          parts << "-i #{rule.in}" if rule.in
          parts << "-o #{rule.out}" if rule.out
          parts
        end

        def emit_proto(rule)
          "-p #{rule.proto}" if rule.proto
        end

        def emit_src(rule)
          emit_src_host(rule) + emit_src_port(rule)
        end

        def emit_src_host(rule)
          if rule.from_host
            ['-s', emit_address(rule.from_host)]
          else
            []
          end
        end

        def emit_src_port(rule)
          if rule.from_port
            ['--sport', emit_port(rule.from_port)]
          else
            []
          end
        end

        def emit_dst(rule)
          emit_dst_host(rule) + emit_dst_port(rule)
        end

        def emit_dst_host(rule)
          if rule.to_host
            ['-d', emit_address(rule.to_host)]
          else
            []
          end
        end

        def emit_dst_port(rule)
          if rule.to_port
            ['--dport', emit_port(rule.to_port)]
          else
            []
          end
        end

        def emit_redirect_or_dnat(rule)
          if Puffy::Formatters::Base.loopback_addresses.include?(rule.rdr_to_host)
            emit_redirect(rule)
          else
            emit_dnat(rule)
          end
        end

        def emit_redirect(rule)
          "-j REDIRECT --to-port #{rule.rdr_to_port}"
        end

        def emit_dnat(rule)
          res = "-j DNAT --to-destination #{rule.rdr_to_host}"
          res += ":#{rule.rdr_to_port}" if rule.rdr_to_port && rule.rdr_to_port != rule.to_port
          res
        end

        def emit_jump(rule)
          "-j #{Puffy::Formatters::Netfilter.iptables_action(rule)}"
        end

        def pp_rule(parts)
          parts.flatten.compact.join(' ')
        end
      end
    end
  end
end
