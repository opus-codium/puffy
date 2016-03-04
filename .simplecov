# vim:set syntax=ruby:
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter,
]
SimpleCov.start do
  add_filter '/spec/'
  add_group 'Formatters', 'lib/melt/formatters'
end
