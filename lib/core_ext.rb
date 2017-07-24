# frozen_string_literal: true

# Mixin for combining variations
#
#   { a: :b }.expand       #=> [{ a: :b }]
#   { a: [:b, :c] }.expand #=> [{ a: :b }, { a: :c }]
#   {
#     a: [:b, :c],
#     d: [:e, :f],
#   }.expand
#   #=> [{ a: :b, d: :e }, {a: :b, d: :f}, { a: :c, d: :e }, { a: :c, d: :f }]
module Expandable
  # Returns an array composed of all possible variation of the object by
  # combining all the items of it's array values.
  #
  # @return [Array]
  def expand
    @expand_res = [{}]
    each do |key, value|
      case value
      when Array then expand_array(key)
      when Hash then expand_hash(key)
      else @expand_res.map! { |hash| hash.merge(key => value) }
      end
    end
    @expand_res
  end

  private

  def expand_array(key)
    orig = @expand_res
    @expand_res = []
    fetch(key).each do |value|
      @expand_res += orig.map { |hash| hash.merge(key => value) }
    end
  end

  def expand_hash(key)
    orig = @expand_res
    @expand_res = []
    fetch(key).expand.each do |value|
      @expand_res += orig.map { |hash| hash.merge(key => value) }
    end
  end
end

class Hash # :nodoc:
  include Expandable
end
