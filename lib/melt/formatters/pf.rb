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
        parts.join(' ')
      end

    protected
      # Return a valid PF representation of +host+.
      def emit_address(host)
        if host then
          super
        else
          'any'
        end
      end
    end
  end
end
