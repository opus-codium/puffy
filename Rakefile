# frozen_string_literal: true

require 'puffy/version'

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'cucumber'
require 'cucumber/rake/task'
require 'github_changelog_generator/task'

RSpec::Core::RakeTask.new(:spec)
Cucumber::Rake::Task.new(:features)

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.user = 'opus-codium'
  config.project = 'puffy'
  config.exclude_labels = ['skip-changelog']
  config.future_release = "v#{Puffy::VERSION}"
end

task test: %i[spec features]

task default: :test

task build: :gen_parser

desc 'Generate the puffy language parser'
task gen_parser: 'lib/puffy/parser.tab.rb'

file 'lib/puffy/parser.tab.rb' => 'lib/puffy/parser.y' do
  `racc -S lib/puffy/parser.y`
end
