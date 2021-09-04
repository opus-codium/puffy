# frozen_string_literal: true

module Melt
  # Melt::Rule factory
  class RuleFactory
    # Initialize a Melt::Rule factory.
    def initialize
      @af = nil
      @resolver = Resolver.instance
      load_services
    end

    # Limit the scope of a set of rules to IPv4 only.
    def ipv4
      raise 'Address familly already scopped' if @af

      @af = :inet
      yield
      @af = nil
    end

    # Limit the scope of a set of rules to IPv6 only.
    def ipv6
      raise 'Address familly already scopped' if @af

      @af = :inet6
      yield
      @af = nil
    end

    # Return an Array of Melt::Rule for the provided +options+.
    # @param [Hash] options
    # @return [Array<Melt::Rule>]
    def build(options = {})
      return [] if options == {}

      options = expand_endpoints(options)

      options = { action: nil, return: false, dir: nil, af: nil, proto: nil, on: nil, from: { host: nil, port: nil }, to: { host: nil, port: nil }, nat_to: nil, rdr_to: { host: nil, port: nil } }.merge(options)

      options = resolv_hostnames_and_ports(options)
      instanciate_rules(options)
    end

    private

    def expand_endpoints(options)
      %i[from to rdr_to].each do |endpoint|
        if options[endpoint].is_a?(String)
          host, port = options[endpoint].split(':', 2)
          options[endpoint] = { host: host, port: port }
        end
      end
      options
    end

    def resolv_hostnames_and_ports(options)
      %i[from to rdr_to].each do |endpoint|
        options[endpoint][:host] = host_lookup(options[endpoint][:host])
        options[endpoint][:port] = port_lookup(options[endpoint][:port])
      end
      options[:nat_to] = host_lookup(options[:nat_to])
      options
    end

    def instanciate_rules(options)
      options.expand.map do |hash|
        rule = Rule.new(hash)
        rule if af_match_policy?(rule.af)
      rescue AddressFamilyConflict
        nil
      end.compact
    end

    def load_services
      @services = {}
      File.readlines('/etc/services').each do |line|
        line.sub!(/#.*/, '')
        pieces = line.split
        next if pieces.count < 2

        port = pieces.delete_at(1).to_i
        pieces.each do |piece|
          @services[piece] = port
        end
      end
    end

    def af_match_policy?(af)
      @af.nil? || af.nil? || af == @af
    end

    def host_lookup(host)
      case host
      when '', nil
        nil
      when String
        @resolver.resolv(host)
      when Array
        host.map { |x| @resolver.resolv(x) }.flatten
      end
    end

    def port_lookup(port)
      case port
      when Integer, String
        real_port_lookup(port)
      when Array
        port.map { |x| port_lookup(x) }
      when nil
        nil
      end
    end

    def real_port_lookup(port)
      res = port_is_a_number(port) || port_is_a_range(port) || @services[port]

      raise "unknown service \"#{port}\"" unless res

      res
    end

    def port_is_a_number(port)
      port.to_i if port.is_a?(Integer) || port =~ /^\d+$/
    end

    def port_is_a_range(port)
      return unless /^(?<start>\d+):(?<stop>\d+)$/ =~ port

      Range.new(start.to_i, stop.to_i)
    end
  end
end
