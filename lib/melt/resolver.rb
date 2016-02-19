require 'ipaddress'
require 'resolv'

module Melt
  # DNS resolution class.
  class Resolver
    # Return the Resolver instance.
    def self.instance
      @@instance ||= new
    end

    # Resolve +hostname+ and return an Array of IPAddress.
    #
    # Valid +address_family+ values are:
    #
    # :inet::   Return only IPv4 addresses;
    #
    # :inet6::  Return only IPv6 addresses;
    def resolv(hostname, address_family = nil)
      resolv_ipaddress(hostname, address_family) || resolv_hostname(hostname, address_family)
    end

    private

    def resolv_ipaddress(address, address_family)
      filter_af(IPAddress.parse(address), address_family)
    rescue ArgumentError
      nil
    end

    def filter_af(address, address_family)
      if address_family
        if address.ipv6? && address_family == :inet || address.ipv4? && address_family == :inet6
          return []
        end
      end
      [address]
    end

    def resolv_hostname(hostname, address_family)
      result = []
      result += resolv_hostname_ipv6(hostname) if address_family.nil? || address_family == :inet6
      result += resolv_hostname_ipv4(hostname) if address_family.nil? || address_family == :inet
      fail "\"#{hostname}\" does not resolve to any valid IP#{@af_str[address_family]} address." if result.empty?
      result
    end

    def resolv_hostname_ipv6(hostname)
      @dns.getresources(hostname, Resolv::DNS::Resource::IN::AAAA).collect { |r| IPAddress.parse(r.address.to_s) }
    end

    def resolv_hostname_ipv4(hostname)
      @dns.getresources(hostname, Resolv::DNS::Resource::IN::A).collect { |r| IPAddress.parse(r.address.to_s) }
    end

    def initialize # :nodoc:
      @dns = Resolv::DNS.open
      @af_str = { inet: 'v4', inet6: 'v6' }
    end
  end
end
