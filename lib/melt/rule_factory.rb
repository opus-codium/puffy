require 'scanf'

module Melt
  # Rule factory
  class RuleFactory
    # Initialize a Rule factory.
    def initialize
      @af = nil
      @services = {}
      File.open('/etc/services') do |f|
        while line = f.gets do
          pieces = line.scanf("%s\t%d/%s")
          next unless pieces.count == 3
          @services[pieces[0]] = pieces[1]
        end
      end
    end

    # Limit the scope of a set of rules to IPv4 only.
    def ipv4
      old_af = @af
      @af = :inet
      yield
      @af = old_af
    end

    # Limit the scope of a set of rules to IPv6 only.
    def ipv6
      old_af = @af
      @af = :inet6
      yield
      @af = old_af
    end

    # Return an Array of Rule for the provided +options+.
    def build(options = {})
      return [] if options == {}

      options = { action: nil, dir: nil, af: nil, proto: nil, on: nil, from: { host: nil, port: nil }, to: { host: nil, port: nil }, nat_to: nil, rdr_to: { host: nil, port: nil } }.merge(options)
      result = []

      options[:dir].to_array.each do |dir|
        filter_af(options[:af]) do |af|
          options[:proto].to_array.each do |proto|
            options[:on].to_array.each do |on_if|
            options[:in].to_array.each do |in_if|
            options[:out].to_array.each do |out_if|
              options[:from].to_array.each do |from|
                host_loockup(from[:host].to_array, af) do |from_host, src_af|
                  from[:port].to_array.each do |from_port|
                    options[:to].to_array.each do |to|
                      host_loockup(to[:host].to_array, src_af) do |to_host, final_af|
                        to[:port].to_array.each do |to_port|
                          host_loockup(options[:nat_to].to_array, final_af) do |nat_to|
                            options[:rdr_to].to_array.each do |rdr_to|
                              host_loockup(rdr_to[:host].to_array, final_af) do |rdr_to_host|
                                rdr_to[:port].to_array.each do |rdr_to_port|
                                  result << Rule.new(action: options[:action], dir: dir, af: final_af, proto: proto, on: on_if, in: in_if, out: out_if, from: { host: from_host, port: port_loockup(from_port) }, to: {host: to_host, port: port_loockup(to_port)}, rdr_to: { host: rdr_to_host, port: rdr_to_port }, nat_to: nat_to)
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
            end
            end
          end
        end
      end

      result
    end

  private
    def filter_af(af)
      if @af.nil? || af.nil? || af == @af then
        yield(af || @af)
      end
    end

    def host_loockup(host, address_family = nil)
      return nil if host.nil?

      resolver = Melt::Resolver.get_instance
      host.collect do |name|
        if name.nil? then
          yield(nil, address_family)
        else
          resolver.resolv(name, address_family).each do |address|
            yield(address, address.ipv6? ? :inet6 : :inet)
          end
        end
      end
    end

    def port_loockup(port)
      return nil if port.nil?

      if port.is_a?(Fixnum) || port =~ /^\d+:\d+$/ then
        port
      else
        raise "unknown service \"#{port}\"" unless @services[port]
        @services[port]
      end
    end
  end
end
