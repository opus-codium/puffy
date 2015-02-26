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

    def ipv4
      old_af = @af
      @af = :inet
      yield
      @af = old_af
    end

    def ipv6
      old_af = @af
      @af = :inet6
      yield
      @af = old_af
    end

    # Return an Array of Rule for the provided +options+.
    def build(options = {})
      return [] if options == {}

      options = { action: nil, dir: nil, af: nil, proto: nil, iface: nil, src: { host: nil, port: nil }, dst: { host: nil, port: nil } }.merge(options)
      result = []

      options[:dir].to_array.each do |dir|
        filter_af(options[:af]) do |af|
          options[:proto].to_array.each do |proto|
            options[:iface].to_array.each do |iface|
              options[:src].to_array.each do |src|
                host_loockup(src[:host].to_array, af) do |src_host, src_af|
                  src[:port].to_array.each do |src_port|
                    options[:dst].to_array.each do |dst|
                      host_loockup(dst[:host].to_array, src_af) do |dst_host, final_af|
                        dst[:port].to_array.each do |dst_port|
                          result << Rule.new(action: options[:action], dir: dir, af: final_af, proto: proto, iface: iface, src: { host: src_host, port: port_loockup(src_port) }, dst: {host: dst_host, port: port_loockup(dst_port)})
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
      if af.nil? || @af == af then
        yield(@af || af)
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
