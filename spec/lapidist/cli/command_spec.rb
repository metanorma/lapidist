require "spec_helper"

RSpec.describe Lapidist::Cli do
  it "test dry-run deny start" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[start -g #{all_gems.join(',')} --verbose -n -d -p #{path} -b feature/x]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    expect(output).to include("run system")

    clean_gems_playground path
  end

  it "test dry-run silent start" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[start -g "#{all_gems.join(',')}" -p #{path} -d --verbose -b feature/x]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    # TODO Add validation

    clean_gems_playground path
  end

  it "test dry-run rake" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[rake -g "#{all_gems.join(',')}" -p #{path} -d -b feature/x]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    # TODO Add validation

    clean_gems_playground path
  end

  it "test dry-run deny push" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[push -g "#{all_gems.join(',')}" -p #{path} -b feature/x -d -n]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    # TODO Add validation

    clean_gems_playground path
  end

  it "test dry-run silent push" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[push -g "#{all_gems.join(',')}" -p #{path} -b feature/x -d -y]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    # TODO Add validation

    clean_gems_playground path
  end

  it "test dry-run finish" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[finish -g "#{all_gems.join(',')}" -p #{path} -b feature/x -d -y]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    # TODO Add validation

    clean_gems_playground path
  end

  it "test dry-run deny finish" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[finish -g "#{all_gems.join(',')}" -p #{path} -b feature/x -n]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    # TODO Add validation

    clean_gems_playground path
  end

  it "test dry-run release" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[release -g "#{all_gems.join(',')}" -p #{path} -b feature/x -d]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    # TODO Add validation

    clean_gems_playground path
  end
end
