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
  class MeltError < RuntimeError
    def initialize(message, token)
      super(message)
      @token = token
    end

    def filename
      @token[:filename]
    end

    def lineno
      @token[:lineno]
    end

    def line
      @token[:line]
    end

    def position
      @token[:position]
    end

    def length
      @token.fetch(:length, 1)
    end

    def extra
      '~' * (length - 1)
    end

    def to_s
      <<~MESSAGE
        #{filename}:#{lineno}:#{position + 1}: #{super}
        #{line}
        #{' ' * position}^#{extra}
      MESSAGE
    end
  end

  class ParseError < MeltError
  end

  class SyntaxError < MeltError
  end
end
