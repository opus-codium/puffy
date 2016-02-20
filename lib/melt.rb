require 'core_ext'

require 'melt/dsl'
require 'melt/formatters/base'
require 'melt/formatters/netfilter'
require 'melt/formatters/netfilter4'
require 'melt/formatters/netfilter6'
require 'melt/formatters/pf'
require 'melt/resolver'
require 'melt/rule'
require 'melt/rule_factory'

module Melt # :nodoc:
  # Melt version String
  VERSION = '1.0.0'.freeze
end
