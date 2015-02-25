module Melt
  module Formatters
    # Netfilter implementation of a Melt formatter.
    class Netfilter < Base
      # Returns a Netfilter String representation of the provided +rule+ Rule.
      def emit_rule(rule)
        parts = []
        parts << "-A #{iptables_direction(rule.dir)}"
        if rule.iface then
          if rule.iface =~ /!(.*)/ then
            parts << "! -i #{$1}"
          else
            parts << "-i #{rule.iface}"
          end
        end
        parts << "-p #{rule.proto}" if rule.proto
        parts << "-s #{emit_address(rule.src[:host])}" if rule.src && rule.src[:host]
        parts << "--sport #{rule.src[:host]}" if rule.src && rule.src[:port]
        parts << "-d #{emit_address(rule.dst[:host])}" if rule.dst && rule.dst[:host]
        parts << "--dport #{rule.dst[:port]}" if rule.dst && rule.dst[:port]
        parts << "-j #{iptables_action(rule.action)}"
        parts.join(' ')
      end

    private
      def iptables_direction(direction)
        case direction
        when :in then 'INPUT'
        when :out then 'OUTPUT'
        end
      end

      def iptables_action(action)
        case action
        when :pass then 'ACCEPT'
        when :log then 'LOG'
        when :block then 'REJECT'
        end
      end
    end
  end
end
