# frozen_string_literal: true

require 'open-uri'
require 'resolv'
require 'singleton'

module Puffy
  # DNS resolution class.
  class Resolver
    include Singleton

    # Resolve +hostname+ and return an Array of IPAddr.
    #
    # @example
    #   Resolver.instance.resolv('localhost')
    #   #=> [#<IPAddr:[::1]>, #<IPAddr:127.0.0.1>]
    #   Resolver.instance.resolv('localhost', :inet)
    #   #=> [#<IPAddr:127.0.0.1>]
    #   Resolver.instance.resolv('localhost', :inet6)
    #   #=> [#<IPAddr:[::1]>]
    #
    # @param hostname [String] The hostname to resolve
    # @param address_family [Symbol] if set, limit search to +address_family+, +:inet+ or +:inet6+
    # @return [Array<IPAddr>]
    def resolv(hostname, address_family = nil)
      if hostname.is_a?(IPAddr)
        resolv_ipaddress(hostname, address_family)
      else
        resolv_hostname(hostname, address_family)
      end
    end

    # Resolve the SRV record for +service+ and return its target and port.
    #
    # @example
    #   Resolver.instance.resolv_srv('_http._tcp.deb.debian.org')
    #   #=> [{ host: 'debian.map.fastlydns.net.', port: 80 }]
    #
    # @param service [String] The service to resolve
    # @return [Array<Hash>]
    def resolv_srv(service)
      proto = service.split('.')[1][1..-1].to_sym
      @dns.getresources(service, Resolv::DNS::Resource::IN::SRV).collect { |r| { host: r.target.to_s, port: r.port, proto_hint: proto } }.sort
    end

    def resolv_apt_mirror(url)
      res = []
      http_url = url.sub(%r{^mirror(\+http)?://}, 'http://')
      res << parse_url(http_url)

      URI.parse(http_url).open do |document|
        document.each_line do |line|
          res << parse_url(line)
        end
      end
      res
    end

    private

    def parse_url(url)
      url =~ %r{^([^:]+)://([^/]+)}
      { host: Regexp.last_match(2), port: Regexp.last_match(1), proto_hint: :tcp }
    end

    def resolv_ipaddress(address, address_family)
      filter_af(address, address_family)
    end

    def filter_af(address, address_family)
      return [] if address_family && !match_af?(address, address_family)

      [address]
    end

    def match_af?(address, address_family)
      (address.ipv6? && address_family == :inet6) ||
        (address.ipv4? && address_family == :inet)
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
      @dns.getresources(hostname, record).collect { |r| IPAddr.new(r.address.to_s) }.sort
    end

    def initialize # :nodoc:
      config = nil
      @dns = Resolv::DNS.open(config)
      @af_str = { inet: 'v4', inet6: 'v6' }
    end
  end
end
