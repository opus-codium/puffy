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

  def expand_array(key) # rubocop:disable Metrics/MethodLength
    orig = @expand_res
    @expand_res = []
    fetch(key).each do |value|
      if value.respond_to?(:expand)
        value.expand.each do |v|
          @expand_res += orig.map { |hash| hash.merge(key => v) }
        end
      else
        @expand_res += orig.map { |hash| hash.merge(key => value) }
      end
    end
  end

  def expand_hash(key) # rubocop:disable Metrics/MethodLength
    orig = @expand_res
    @expand_res = []
    fetch(key).expand.each do |value|
      if value.respond_to?(:expand)
        value.expand.each do |v|
          @expand_res += orig.map { |hash| hash.merge(key => v) }
        end
      else
        @expand_res += orig.map { |hash| hash.merge(key => value) }
      end
    end
  end
end

class Array # :nodoc:
  def deep_dup
    array = []
    each do |value|
      array << if value.respond_to?(:deep_dup)
                 value.deep_dup
               else
                 value.dup
               end
    end
    array
  end
end

class Hash # :nodoc:
  include Expandable

  def deep_dup
    hash = dup
    each_pair do |key, value|
      hash[key.dup] = if value.respond_to?(:deep_dup)
                        value.deep_dup
                      else
                        value.dup
                      end
    end
    hash
  end
end
