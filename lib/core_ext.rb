class Array
  # Return an Array of resolved IPAddress for a given Array of hostnames.
  #
  # Valid +address_family+ values are:
  #
  # :inet::   Return only IPv4 addresses;
  #
  # :inet6::  Return only IPv6 addresses;
  #
  #   ['localhost.'].resolve         #=> [#<IPAddress::IPv6 @compressed="::1">, #<IPAddress::IPv4 @address="127.0.0.1">]
  #   ['localhost.'].resolve(:inet)  #=> [#<IPAddress::IPv4 @address="127.0.0.1">]
  #   ['localhost.'].resolve(:inet6) #=> [#<IPAddress::IPv6 @compressed="::1">]
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

class NilClass
  # Allow nil to yield with no value.
  #
  #   foo = [1, 2, 3]
  #   bar = nil
  #
  #   foo.each { |x| puts "foo: #{x.inspect}" }
  #   bar.each { |x| puts "bar: #{x.inspect}" }
  # <i>produces:</i>
  #   foo: 1
  #   foo: 2
  #   foo: 3
  #   bar: nil
  def each
    yield(nil)
  end
end

class Object
  # Return self packed in an array unless self itself is an Array.
  #
  #   1.to_array         #=> [1]
  #   'string'.to_array  #=> ['string']
  #   [1, 2, 3].to_array #=> [1, 2, 3]
  def to_array
    if self.is_a?(Array) then
      self
    else
      [self]
    end
  end
end
