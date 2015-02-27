class Object # :nodoc:
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
