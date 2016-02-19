# vim:set syntax=ruby:
SimpleCov.start do
  add_filter '/spec/'
  add_group 'Formatters', 'lib/melt/formatters'
end
