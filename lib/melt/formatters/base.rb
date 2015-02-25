module Melt
  module Formatters
    # Base class for Melt Formatters.
    class Base
    protected
      # Return a string representation of the +host+ IPAddress as a host or network.
      def emit_address(host)
        if host.ipv4? && host.prefix.to_i == 32 ||
          host.ipv6? && host.prefix.to_i == 128 then
          host.to_s
        else
          host.to_string
        end
      end
    end
  end
end
