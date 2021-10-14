# frozen_string_literal: true

require 'core_ext'

require 'puffy/parser.tab'
require 'puffy/formatters/base'
require 'puffy/formatters/netfilter'
require 'puffy/formatters/netfilter4'
require 'puffy/formatters/netfilter6'
require 'puffy/formatters/pf'
require 'puffy/puppet'
require 'puffy/resolver'
require 'puffy/rule'
require 'puffy/rule_factory'
require 'puffy/version'

module Puffy
  # Base class for application errors with a configuration file
  class PuffyError < RuntimeError
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

  # Invalid configuration file
  class ParseError < PuffyError
  end

  # Syntax error in configuration file
  class SyntaxError < PuffyError
  end
end
