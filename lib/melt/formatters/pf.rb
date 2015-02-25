module Melt
  module Formatters
    # Pf implementation of a Melt formatter.
    class Pf < Base
      # Returns a Pf String representation of the provided +rule+ Rule.
      def emit_rule(rule)
        parts = []
        parts << rule.action
        parts << rule.dir if rule.dir
        parts << rule.af if rule.af
        parts << "proto #{rule.proto}" if rule.proto
        if rule.src then
          parts << "from #{emit_address(rule.src[:host])}"
          parts << "port #{rule.src[:port]}" if rule.src
        end
        if rule.dst then
          parts << "to #{emit_address(rule.dst[:host])}"
          parts << "port #{rule.dst[:port]}" if rule.dst
        end
        if rule.src.nil? and rule.dst.nil? then
          parts << 'all'
        end
        parts.join(' ')
      end

    protected
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
