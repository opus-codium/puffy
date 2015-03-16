module Melt
  module Formatters
    # Netfilter implementation of a Melt formatter.
    class Netfilter < Base
      # Returns a Netfilter String representation of the provided +rule+ Rule.
      def emit_rule(rule)
        parts = []
        on_direction_flag = { in: '-i', out: '-o', }
        parts << "-A #{iptables_direction(rule.dir)}"
        if rule.on then
          if rule.on =~ /!(.*)/ then
            parts << "! #{on_direction_flag[rule.dir]} #{$1}"
          else
            parts << "#{on_direction_flag[rule.dir]} #{rule.on}"
          end
        else
          if rule.in then
            parts << "-i #{rule.in}"
          end
          if rule.out then
            parts << "-o #{rule.out}"
          end
        end
        parts << "-p #{rule.proto}" if rule.proto
        parts << "-s #{emit_address(rule.from[:host])}" if rule.from && rule.from[:host]
        parts << "--sport #{rule.src_port}" if rule.from && rule.src_port
        parts << "-d #{emit_address(rule.to[:host])}" if rule.to && rule.to[:host]
        parts << "--dport #{rule.dst_port}" if rule.to && rule.dst_port
        parts << "-j #{iptables_action(rule.action)}"
        parts.join(' ')
      end

      # Returns a Netfilter String representation of the provided +rules+ Array of Rule with the +policy+ policy.
      def emit_ruleset(rules, policy = :block)
        parts = []
        parts << '*filter'
        parts << super
        parts << 'COMMIT'
        parts.join("\n")
      end

    private
      def iptables_direction(direction)
        case direction
        when :in then 'INPUT'
        when :out then 'OUTPUT'
        when :fwd then 'FORWARD'
        end
      end

      def iptables_action(rule_or_action)
        action, ret = if rule_or_action.is_a?(Symbol) then
          [rule_or_action, nil]
        else
          [rule_or_action.action, rule_or_action.return]
        end
        case action
        when :pass then 'ACCEPT'
        when :log then 'LOG'
        when :block then
          if ret then
            'RETURN'
          else
            'DROP'
          end
        end
      end
    end
  end
end
