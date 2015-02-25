require 'ipaddress'
require 'resolv'

module Melt
  # DNS resolution class.
  class Resolver
    # Return the Resolver instance.
    def self.get_instance
      @@instance ||= new
    end

    # Resolve hostname and return an Array of IPAddress.
    #
    # Valid +address_family+ values are:
    #
    # :inet::   Return only IPv4 addresses;
    #
    # :inet6::  Return only IPv6 addresses;
    def resolv(hostname, address_family = nil)
      addr = IPAddress.parse(hostname)
      return[addr]
    rescue
      result = []
      result += @dns.getresources(hostname, Resolv::DNS::Resource::IN::AAAA).collect { |r| IPAddress.parse(r.address.to_s) } if address_family.nil? or address_family == :inet6
      result += @dns.getresources(hostname, Resolv::DNS::Resource::IN::A).collect { |r| IPAddress.parse(r.address.to_s) } if address_family.nil? or address_family == :inet
      result
    end

  private
    def initialize # :nodoc:
      @dns = Resolv::DNS.open
    end
  end
end
