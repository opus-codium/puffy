require 'simplecov'
require 'aruba/cucumber'
require 'melt/cli'

class Runner
  def initialize(argv, stdin, stdout, stderr, kernel)
    @argv   = argv
    @stdin  = stdin
    @stdout = stdout
    @stderr = stderr
    @kernel = kernel
  end

  def execute!
    Melt::Cli::Main.start(@argv)
  end
end

Before('@in-process') do
  aruba.config.command_launcher = :in_process
  aruba.config.main_class = Runner
end

After('@in-process') do
  aruba.config.command_launcher = :spawn
end
