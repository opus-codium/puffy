module Melt
  module Formatters # :nodoc:
    # Base class for Melt Formatters.
    class Base
      def initialize
        @loopback_addresses = [nil, loopback_ipv4, loopback_ipv6]
      end

      # Returns a String representation of the provided +rules+ Array of Melt::Rule with the +policy+ policy.
      #
      # @param rules [Array<Melt::Rule>] array of Melt::Rule.
      # @param _policy [Symbol] ruleset policy.
      # @return [String]
      def emit_ruleset(rules, _policy = nil)
        rules.collect { |rule| emit_rule(rule) }.join("\n")
      end

      protected

      # Returns the loopback IPAddress of the given +address_family+
      #
      # @param address_family [Symbol] the address family, +:inet+ or +:inet6+
      # @return [IPAddress,nil]
      def loopback_address(address_family)
        case address_family
        when :inet then loopback_ipv4
        when :inet6 then loopback_ipv6
        when nil then nil
        else fail "Unsupported address family #{address_family.inspect}"
        end
      end

      # Returns the loopback IPv4 IPAddress
      #
      # @return [IPAddress]
      def loopback_ipv4
        IPAddress.parse('127.0.0.1')
      end

      # Returns the loopback IPv6 IPAddress
      #
      # @return [IPAddress]
      def loopback_ipv6
        IPAddress::IPv6::Loopback.new
      end

      # Return a string representation of the +host+ IPAddress as a host or network.
      # @param host [IPAddress]
      # @return [String] IP address
      def emit_address(host)
        if host.ipv4? && host.prefix.to_i == 32 || host.ipv6? && host.prefix.to_i == 128
          host.to_s
        else
          host.to_string
        end
      end
    end
  end
end
