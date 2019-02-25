# frozen_string_literal: true

# Comparison should not raise an exception.
# https://github.com/ipaddress-gem/ipaddress/pull/76

require 'ipaddress'

module IPAddress
  class IPv4 # :nodoc:
    def <=>(other)
      return nil unless other.is_a?(self.class)
      return prefix <=> other.prefix if to_u32 == other.to_u32

      to_u32 <=> other.to_u32
    end
  end

  class IPv6 # :nodoc:
    def <=>(other)
      return nil unless other.is_a?(self.class)
      return prefix <=> other.prefix if to_u128 == other.to_u128

      to_u128 <=> other.to_u128
    end
  end
end
