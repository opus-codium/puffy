# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'cucumber'
require 'cucumber/rake/task'

RSpec::Core::RakeTask.new(:spec)
Cucumber::Rake::Task.new(:features)

task test: %i[spec features]

task default: :test

desc 'Generate the puffy language parser'
task gen_parser: 'lib/puffy/parser.tab.rb'

file 'lib/puffy/parser.tab.rb' => 'lib/puffy/parser.y' do
  `racc -S lib/puffy/parser.y`
end
