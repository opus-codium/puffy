class Object
  def to_array
    if self.is_a?(Array) then
      self
    else
      [self]
    end
  end
end

class NilClass
  def each
    yield(nil)
  end
end

class Array
  def resolve(address_family = nil)
    resolver = Melt::Resolver.get_instance
    collect do |name|
      if name.nil? then
        yield(nil)
      else
        resolver.resolv(name, address_family).each do |address, af|
          yield(address, af)
        end
      end
    end
  end
end

module Melt
  class RuleFactory
    def self.build(options = {})
      return [] if options == {}

      options = { dir: nil, af: nil, proto: nil, iface: nil, src: { host: nil, port: nil }, dst: { host: nil, port: nil } }.merge(options)
      result = []

      options[:dir].to_array.each do |dir|
        options[:af].to_array.each do |af|
          options[:proto].to_array.each do |proto|
            options[:iface].each do |iface|
              options[:src].to_array.each do |src|
                src[:host].to_array.resolve(af) do |src_host, src_af|
                  src[:port].to_array.each do |src_port|
                    options[:dst].to_array.each do |dst|
                      dst[:host].to_array.resolve(src_af) do |dst_host|
                        dst[:port].to_array.each do |dst_port|
                          result << Rule.new(dir: dir, af: af, proto: proto, iface: iface, src: { host: src_host, port: src_port }, dst: {host: dst_host, port: dst_port})
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
  end
end
