require "spec_helper"

RSpec.describe Lapidist::Cli do
  it 'test dry-run deny start' do
    all_gems = %w[a b c d e]
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[start -g #{all_gems.join(',')} -p #{path} -b feature/x -d -y --verbose]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    expect(output).to include('start feature branch')
    expect(output).to include('was started')

    clean_gems_playground path
  end

  it 'test dry-run silent start' do
    all_gems = %w[a b c d e]
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[start -g #{all_gems.join(',')} -p #{path} -b feature/x -d -n --verbose]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    expect(output).to include('start feature branch')
    expect(output).to include('was started')

    clean_gems_playground path
  end

  it 'test dry-run rake' do
    all_gems = %w[a b c d e]
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[rake -g #{all_gems.join(',')} -p #{path} -b feature/x -d --verbose]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    expect(output).to include('start tests for branch')
    expect(output).to include('was executed')

    clean_gems_playground path
  end

  it 'test dry-run deny push' do
    all_gems = %w[a b c d e]
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[push -g #{all_gems.join(',')} -p #{path} -b feature/x -d -n --verbose]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    expect(output).to include('was executed')

    clean_gems_playground path
  end

  it 'test dry-run silent push' do
    all_gems = %w[a b c d e]
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[push -g #{all_gems.join(',')} -p #{path} -b feature/x -d -y --verbose]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    expect(output).to include('was executed')

    clean_gems_playground path
  end

  it 'test dry-run finish' do
    all_gems = %w[a b c d e]
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[finish -g #{all_gems.join(',')} -p #{path} -b feature/x -d -y --verbose]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    expect(output).to include('was executed')

    clean_gems_playground path
  end

  it 'test dry-run deny finish' do
    all_gems = %w[a b c d e]
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[finish -g #{all_gems.join(',')} -p #{path} -b feature/x -n --verbose]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    expect(output).to include('was executed')

    clean_gems_playground path
  end

  it 'test dry-run release' do
    all_gems = %w[a b c d e]
    path = 'tmp'

    create_gems_playground path, all_gems

    command = %W[release -g #{all_gems.join(',')} -p #{path} -v patch -d --verbose]
    output = capture_stdout {
      Lapidist::Cli::Command.start(command)
    }

    expect(output).to include('was executed')

    clean_gems_playground path
  end
end
