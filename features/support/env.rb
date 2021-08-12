# frozen_string_literal: true

require 'aruba/cucumber'
require 'melt/cli'

class Runner
  def initialize(argv, stdin, stdout, stderr, kernel)
    @argv   = argv
    $stdin  = stdin
    $stdout = stdout
    $stderr = stderr
    $kernel = kernel
  end

  def execute!
    Melt::Cli.new.execute(@argv)
  end
end

Aruba.config.command_launcher = :in_process
Aruba.config.main_class = Runner
