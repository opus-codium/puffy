# frozen_string_literal: true

require 'core_ext'

require 'melt/parser.tab'
require 'melt/formatters/base'
require 'melt/formatters/netfilter'
require 'melt/formatters/netfilter4'
require 'melt/formatters/netfilter6'
require 'melt/formatters/pf'
require 'melt/puppet'
require 'melt/resolver'
require 'melt/rule'
require 'melt/rule_factory'
require 'melt/version'

module Melt
  class SyntaxError < RuntimeError
    attr_reader :filename, :lineno, :position, :line

    def initialize(message, options)
      super(message)
      @filename = options[:filename]
      @lineno = options[:lineno]
      @position = options[:position]
      @line = options[:line]
    end

    def to_s
      <<~MESSAGE
        #{filename}:#{lineno}:#{position + 1}: #{super}
        #{line}
        #{' ' * (position)}^
      MESSAGE
    end
  end
end
