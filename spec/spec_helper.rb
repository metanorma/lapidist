require "bundler/setup"
require "lapidist/cli/command"
require "support/console_helper"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Metanorma::ConsoleHelper
end

def create_gems_playground(path, gems, max_deps=0)
  FileUtils.mkdir_p path
  Dir.chdir path do
  	gems.each { |g|
      `gem gemspec #{g}`
      `git -C #{g} init`
    }
  end
end

def clean_gems_playground(path)
  FileUtils.rm_rf(path)
end