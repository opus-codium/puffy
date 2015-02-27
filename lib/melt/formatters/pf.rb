module Melt
  module Formatters
    # Pf implementation of a Melt formatter.
    class Pf < Base
      # Returns a Pf String representation of the provided +rule+ Rule.
      def emit_rule(rule)
        parts = []
        parts << rule.action
        parts << rule.dir if rule.dir
        parts << 'quick' unless rule.no_quick
        parts << rule.af if rule.af
        parts << "proto #{rule.proto}" if rule.proto
        if rule.src then
          parts << "from #{emit_address(rule.src[:host])}"
          parts << "port #{rule.src_port}" if rule.src_port
        end
        if rule.dst then
          parts << "to #{emit_address(rule.dst[:host])}"
          parts << "port #{rule.dst_port}" if rule.dst_port
        end
        if rule.src.nil? && rule.dst.nil? then
          parts << 'all'
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
