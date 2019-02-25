# frozen_string_literal: true

require 'ipaddress'
require 'resolv'
require 'singleton'

module Melt
  # DNS resolution class.
  class Resolver
    include Singleton

    # Resolve +hostname+ and return an Array of IPAddress.
    #
    # @example
    #   Resolver.instance.resolv('localhost')
    #   #=> [#<IPAddress:[::1]>, #<IPAddress:127.0.0.1>]
    #   Resolver.instance.resolv('localhost', :inet)
    #   #=> [#<IPAddress:127.0.0.1>]
    #   Resolver.instance.resolv('localhost', :inet6)
    #   #=> [#<IPAddress:[::1]>]
    #
    # @param hostname [String] The hostname to resolve
    # @param address_family [Symbol] if set, limit search to +address_family+, +:inet+ or +:inet6+
    # @return [Array<IPAddress>]
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
        return [] if address.ipv6? && address_family == :inet || address.ipv4? && address_family == :inet6
      end
      [address]
    end

    def resolv_hostname(hostname, address_family)
      result = []
      result += resolv_hostname_ipv6(hostname) if address_family.nil? || address_family == :inet6
      result += resolv_hostname_ipv4(hostname) if address_family.nil? || address_family == :inet
      raise "\"#{hostname}\" does not resolve to any valid IP#{@af_str[address_family]} address." if result.empty?

      result
    end

    def resolv_hostname_ipv6(hostname)
      resolv_hostname_record(hostname, Resolv::DNS::Resource::IN::AAAA)
    end

    def resolv_hostname_ipv4(hostname)
      resolv_hostname_record(hostname, Resolv::DNS::Resource::IN::A)
    end

    def resolv_hostname_record(hostname, record)
      @dns.getresources(hostname, record).collect { |r| IPAddress.parse(r.address.to_s) }.sort
    end

    def initialize # :nodoc:
      config = {}
      if ENV['CI'] == 'true' && ENV['TRAVIS'] == 'true'
        # XXX: Travis-CI unreliably resolves IPv6.
        config = {
          nameserver: '1.1.1.1',
          search:     '',
          ndots:      1,
        }
      end
      @dns = Resolv::DNS.open(config)
      @af_str = { inet: 'v4', inet6: 'v6' }
    end
  end
end
