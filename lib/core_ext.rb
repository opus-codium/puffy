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
