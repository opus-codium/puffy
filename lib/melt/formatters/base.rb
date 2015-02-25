module Melt
  module Formatters
    class Base
    protected
      def emit_address(host)
        if host.ipv4? and host.prefix.to_i == 32 or
          host.ipv6? and host.prefix.to_i == 128 then
          host.to_s
        else
          host.to_string
        end
      end
    end
  end
end
