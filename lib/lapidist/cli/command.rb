require "thor"
require "lapidist"

module Lapidist
  module Cli
    class Command < Thor
      class << self
        # https://stackoverflow.com/a/45730659/902217
        def help(shell, subcommand = false)
          list = printable_commands(true, subcommand)
          Thor::Util.thor_classes_in(self).each do |klass|
            list += klass.printable_commands(false)
          end

          # Remove this line to disable alphabetical sorting
          # list.sort! { |a, b| a[0] <=> b[0] }

          # Add this line to remove the help-command itself from the output
          list.reject! {|l| l[0].split[1] == 'help'}

          if defined?(@package_name) && @package_name
            shell.say "#{@package_name} commands:"
          else
            shell.say "Commands:"
          end

          shell.print_table(list, :indent => 2, :truncate => true)
          shell.say
          class_options_help(shell)

          # Add this line if you want to print custom text at the end of your help output.
          # (similar to how Rails does it)
          shell.say <<~BANNER 
All commands can be run with -h (or --help) for more information.'

Workflow:
  A typical flow will be:
  - Before start working on feature X run `lapidist start -b feature/X -g "A B C D"`
  - Do actual development on A, B, C, D gems
  - To execute tests for these gems just run `lapidist rake -b feature/X`
    You can restrict gems with `-g` option too, by default it will run for all gems which was used on lapidist start command
  - If during development you have foundout that:
    - Some gem E need to be added to feature X, just run `lapidist start -b feature/X -g E`
    - Some gem D need to be excluded from feature X, just run `cd D/ && git branch -D feature/X`
  - To push local commits to remote repo run `lapidist push -b feature/X`
  - Once PR good enough, check list bellow, you are ready to merge with `lapidist finish -b feature/X`:
    - `lapidist rake -b feature/X` success
    - CI is green for A, B, C, D, E gems
  - To do release with version bump simply run `Usage: lapidist release -g "a b c d e" -v minor`

Dependencies:
  - https://hub.github.com/ must be installed

Hints:
  All commands have --dry-run & --verbose modes, if you aren't sure about result of some command, try it with dry-run first
BANNER
        end
      end

      class_option :verbose, :desc => "verbose logging", :type => :boolean, :default => false
      class_option :dry_run, aliases: "-d", :desc => "dry-run don't modify anything", :type => :boolean, :default => false
      class_option :silent, aliases: "-y", :desc => "accept all interactive dialogs", :type => :boolean, :default => false
      class_option :deny, aliases: "-n", :desc => "accept all interactive dialogs", :type => :boolean, :default => false
      class_option :path, aliases: "-p", :desc => "path to directory which contains gems (gem repos)", :type => :string, :required => true
      class_option :organization, aliases: "-o", :desc => "GitHub organization", :type => :string, :default => 'metanorma'
      class_option :gems, aliases: "-g", :desc => "comaseparated list of gems to apply command (order make sense)", :type => :string, :default => ""

      desc "start", "Create branch & draft PR on GitHub for listed gems"
      method_option :pr, desc: "Create draft PR", :type => :boolean, :default => true
      method_option :branch, aliases: "-b", desc: "Branch to create", :type => :string, :required => true
      def start
        branch_name = options[:branch]
        path = options[:path]

        gems = options[:gems].split(',') || Lapidist.gems(path)
        gems.concat(Lapidist.gems(path, branch_name)).uniq!
        gem_deps = Lapidist.gem_deps(path, gems)

        Lapidist.log("start feature branch [#{branch_name}] for #{gems} gems", options)

        gems.each do |g|
          gem_project_path = File.join(path, g.to_s)

          Lapidist.log("create branch [#{branch_name}] for [#{g}] gem", options)

          Dir.chdir(gem_project_path) do
            Lapidist.run_cmd("git checkout -b #{branch_name}", options) unless Lapidist.git_branch_is(branch_name)
          end
        end

        gems.each do |g|
          gem_project_path = File.expand_path(File.join(path, g.to_s))

          Lapidist.log("setup local dependencies for [#{g}] gem", options)

          Dir.chdir(gem_project_path) do
            File.open(Lapidist::DEVEL_GEMFILE, 'w') { |file| 
              gem_deps[g.to_s].each do |d|
                file.write("gem '#{d}', #{Lapidist::gem_repo_path_with_opts(d, options[:org])}, :branch => '#{branch_name}'\n")
              end
            }

            Bundler.with_clean_env do
              gem_deps[g.to_s].each do |d|
                Lapidist.run_cmd("bundle config --local local.#{d} #{File.join(path, d)}", options)
              end

              Lapidist.run_cmd("bundle install", options)
            end
          end
        end

        if Lapidist.yesno("push [#{branch_name}] branch to remote right now", options)
          gems.each do |g|
            gem_project_path = File.join(path, g.to_s)
            Dir.chdir(gem_project_path) do
              Lapidist.run_cmd("git push origin #{branch_name}", options)
              Lapidist.run_cmd("hub pull-request -b master --no-edit --draft", options) 
            end
          end
        end

        Lapidist.log("feature branch [#{branch_name}] for #{gems} gems was started", options)
      end

      desc "rake", "Test gems of feature"
      method_option :branch, aliases: "-b", desc: "Branch to create", :type => :string, :required => true
      def rake
        path = options[:path]
        branch_name = options[:branch]
        gems = options[:gems].split(',') || Lapidist.gems(path, branch_name)

        Lapidist.log("start tests for branch [#{branch_name}] gems #{gems}", options)

        gems.each do |g|
          gem_project_path = File.expand_path(File.join(path, g.to_s))

          Dir.chdir(gem_project_path) do
            if Lapidist.git_branch_is(branch_name) && gems.include?(g)
              Lapidist.log("run tests for [#{g}] gem...", options)
              Bundler.with_clean_env do
                #Lapidist.run_cmd("bundle exec rake", options)
                Lapidist.run_cmd("bundle exec rspec --format doc", options)
              end
            else
              Lapidist.log("ignore tests for [#{g}] gem because branch isn't [#{branch_name}]", options)
            end
          end
        end

        Lapidist.log("tests for branch [#{branch_name}] gems #{gems} was executed", options)
      end

      desc "push", "Push commits for gems of feature"
      method_option :branch, aliases: "-b", desc: "Branch to create", :type => :string, :required => true
      def push
        path = options[:path]
        branch_name = options[:branch]
        gems = options[:gems].split(',') || Lapidist.gems(path, branch_name)

        Lapidist.log("start push for branch [#{branch_name}]", options)

        gems.each do |g|
          gem_project_path = File.expand_path(File.join(path, g.to_s))

          Dir.chdir(gem_project_path) do
            if Lapidist.git_branch_is(branch_name)
              Lapidist.log("run push for [#{g}] gem...", options)
              Bundler.with_clean_env do
                Lapidist.run_cmd("git push origin #{branch_name}", options)
              end
            else
              Lapidist.log("ignore tests for [#{g}] gem because branch isn't [#{branch_name}]", options)
            end
          end
        end

        Lapidist.log("push for branch [#{branch_name}] was executed", options)
      end

      desc "finish", "Merge PRs for gems into master"
      method_option :branch, aliases: "-b", desc: "Branch to create", :type => :string, :required => true
      def finish
        branch_name = options[:branch]
        path = options[:path]

        Lapidist.log("merge branch [#{branch_name}] to master", options)

        if Lapidist.yesno("please confirm that all PRs for [#{branch_name}] are 'green'", options)
          gems = options[:gems].split(',') || Lapidist.gems(path)
          gem_deps = Lapidist.gem_deps(path, gems)

          gems.each do |g|
            gem_project_path = File.join(path, g.to_s)
            gem_devel_gemfile = File.join(gem_project_path, Lapidist::DEVEL_GEMFILE)

            Dir.chdir(gem_project_path) do
              next unless Lapidist.git_branch_is(branch_name)

              File.delete(gem_devel_gemfile) unless options[:dry_run]

              Bundler.with_clean_env do
                gem_deps[g].each do |d|
                  Lapidist.run_cmd("bundle config --delete local.#{d} #{File.join(path, d)}", options)
                end

                Lapidist.run_cmd("bundle install", options)
              end

              Lapidist.run_cmd("git add -u #{Lapidist::DEVEL_GEMFILE} Gemfile.lock", options)
              Lapidist.run_cmd("git commit -m \"Feature #{branch_name}\" done", options)
              Lapidist.run_cmd("git push origin #{branch_name}", options)
              Lapidist.run_cmd("git checkout master", options)
              Lapidist.run_cmd("git merge #{branch_name}", options)
              Lapidist.run_cmd("git push origin master", options)
            end
          end
        else
          Lapidist.warn "please fix all issues before finish [#{branch_name}] branch", options
        end

        Lapidist.log("finish for branch [#{branch_name}] was executed", options)
      end

      desc "release", "Bump version & push to git & rubygems.org"
      method_option :version, aliases: "-v", desc: "version part to increment, accepted values: major|minor|patch|pre|release|1.2.3", :type => :string, :required => true
      method_option :gems, aliases: "-g", :desc => "list of gems to apply command (order make sense)", :type => :string, :default => nil, :required => true
      def release
        gems = options[:gems].split(',')
        version = options[:version]
        path = options[:path]

        Lapidist.log("release #{gems} gems...", options)

        gems.each { |g| 
          gem_project_path = File.expand_path(File.join(path, g.to_s))

          Dir.chdir(gem_project_path) do 
            if Lapidist.git_branch_is('master')
              Lapidist.log("do version bump for [#{g}] gem...", options)
              Lapidist.run_cmd("gem bump --tag --push --release --version #{version}", options)
            else
              raise "Stop release for [#{g}] gem because current branch isn't [master]"
            end
          end
        }

        Lapidist.log("release for gems [#{gems}] was executed", options)
      end
    end
  end
end
