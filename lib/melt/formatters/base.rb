module Melt
  module Formatters # :nodoc:
    # Base class for Melt Formatters.
    class Base
      def initialize
        @loopback_addresses = [nil, loopback_address(:inet), loopback_address(:inet6)]
      end

      # Returns a String representation of the provided +rules+ Array of Melt::Rule with the +policy+ policy.
      #
      # @param rules [Array<Melt::Rule>] array of Melt::Rule.
      # @param policy [Symbol] ruleset policy.
      # @return [String]
      def emit_ruleset(rules, _policy = nil)
        rules.collect { |rule| emit_rule(rule) }.join("\n")
      end

      # Returns a loopback address in the specified address family.
      # @param address_family [Symbol] the address family, `:inet` or `:inet6`
      # @return [IPAddress] Loopback address.
      def loopback_address(address_family)
        case address_family
        when :inet then IPAddress.parse('127.0.0.1')
        when :inet6 then IPAddress::IPv6::Loopback.new
        when nil then nil
        else fail "Unsupported address family #{address_family.inspect}"
        end
      end

      protected

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
