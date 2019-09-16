require "spec_helper"

RSpec.describe Lapidist::Cli do
  it "test dry-run deny start" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    gems_paths = 'tmp'

    create_gems_playground gems_paths, all_gems

    cmd = Lapidist::Cli::Command.new

    output = capture_stdout {
      cmd.start({
        gems: all_gems,
        gems_path: gems_paths,
        branch: 'feature/x',
        verbose: false,
        deny: true,
        dry_run: true
      })
    }

    expect(output).to include("run system")

    clean_gems_playground gems_paths
  end

  it "test dry-run silent start" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    gems_paths = 'tmp'

    create_gems_playground gems_paths, all_gems

    cmd = Lapidist::Cli::Command.new

    output = capture_stdout {
      cmd.start({
        gems: all_gems,
        gems_path: gems_paths,
        branch: 'feature/x',
        verbose: false,
        silent: true,
        dry_run: true
      })
    }

    clean_gems_playground gems_paths
  end

  it "test dry-run rake" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    gems_paths = 'tmp'

    create_gems_playground gems_paths, all_gems

    cmd = Lapidist::Cli::Command.new

    output = capture_stdout {
      cmd.rake({
        gems: all_gems,
        gems_path: gems_paths,
        branch: 'feature/x',
        verbose: false,
        dry_run: true
      })
    }

    clean_gems_playground gems_paths
  end

  it "test dry-run deny push" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    gems_paths = 'tmp'

    create_gems_playground gems_paths, all_gems

    cmd = Lapidist::Cli::Command.new

    output = capture_stdout {
      cmd.push({
        gems: all_gems,
        gems_path: gems_paths,
        branch: 'feature/x',
        verbose: false,
        dry_run: true,
        deny: true
      })
    }

    clean_gems_playground gems_paths
  end

  it "test dry-run silent push" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    gems_paths = 'tmp'

    create_gems_playground gems_paths, all_gems

    cmd = Lapidist::Cli::Command.new

    output = capture_stdout {
      cmd.push({
        gems: all_gems,
        gems_path: gems_paths,
        branch: 'feature/x',
        verbose: false,
        dry_run: true,
        silent: true
      })
    }

    clean_gems_playground gems_paths
  end

  it "test dry-run finish" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    gems_paths = 'tmp'

    create_gems_playground gems_paths, all_gems

    cmd = Lapidist::Cli::Command.new

    output = capture_stdout {
      cmd.finish({
        gems: all_gems,
        gems_path: gems_paths,
        branch: 'feature/x',
        verbose: false,
        dry_run: true,
        silent: true
      })
    }

    clean_gems_playground gems_paths
  end

  it "test dry-run deny finish" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    gems_paths = 'tmp'

    create_gems_playground gems_paths, all_gems

    cmd = Lapidist::Cli::Command.new

    output = capture_stdout {
      cmd.finish({
        gems: all_gems,
        gems_path: gems_paths,
        branch: 'feature/x',
        verbose: false,
        deny: true
      })
    }

    clean_gems_playground gems_paths
  end

  it "test dry-run release" do
    all_gems = ['a', 'b', 'c', 'd', 'e']
    gems_paths = 'tmp'

    create_gems_playground gems_paths, all_gems

    cmd = Lapidist::Cli::Command.new

    output = capture_stdout {
      cmd.release({
        gems: all_gems,
        gems_path: gems_paths,
        version: 'patch',
        verbose: false,
        dry_run: true,
      })
    }

    clean_gems_playground gems_paths
  end
end
