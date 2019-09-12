require_relative "../../tool"

module Lapidist
  module Cli
    class Command
      DEVEL_GEMFILE = 'Gemfile.devel'

      # FIXME: generalize!!
      def gem_repo_path_with_opts(gemname, org = "metanorma")
        ":github => '#{org}/#{gemname}'"
      end

      def start(options)
        validate 'start', options

        branch_name = options[:branch]
        path = options[:gems_path]

        leaf_gems = options[:gems] || Lapidist.gems(path)
        gem_deps = Lapidist.gem_deps(path)

        log("start feature branch [#{branch_name}] for #{gems} gems", options)

        leaf_gems.each do |mn_gem|
          gem_project_path = File.join(path, mn_gem.to_s)

          log("create branch [#{branch_name}] for [#{mn_gem}] gem", options)

          Dir.chdir(gem_project_path) do
            run_cmd("git checkout -b #{branch_name}", options)
          end
        end

        leaf_gems.each do |mn_gem|
          gem_project_path = File.expand_path(File.join(path, mn_gem.to_s))

          log("setup local dependencies for [#{mn_gem}] gem", options)

          Dir.chdir(gem_project_path) do
            File.open(DEVEL_GEMFILE, 'w') { |file|
              gem_deps[mn_gem.to_s].each do |d|
                file.write("gem '#{d}', #{gem_repo_path_with_opts(d)}, :branch => '#{branch_name}'\n")
              end
            }

            Bundler.with_clean_env do
              gem_deps[mn_gem.to_s].each do |d|
                run_cmd("bundle config --local local.#{d} #{File.join(path, d)}", options)
              end

              run_cmd("bundle install", options)
            end
          end
        end

        if yesno("push [#{branch_name}] branch to remote right now", options)
          leaf_gems.each do |mn_gem|
            gem_project_path = File.join(path, mn_gem.to_s)
            Dir.chdir(gem_project_path) do
              run_cmd("git push origin #{branch_name}", options)
            end
          end
        end
      end

      def rake(options)
        validate 'rake', options

        path = options[:gems_path]
        branch_name = options[:branch]

        log("start tests for branch [#{branch_name}]", options)

        Lapidist.gems(path).each do |mn_gem|
          gem_project_path = File.expand_path(File.join(path, mn_gem.to_s))

          Dir.chdir(gem_project_path) do
            if git_branch_is(branch_name)
              log("run tests for [#{mn_gem}] gem...", options)
              Bundler.with_clean_env do
                run_cmd("bundle exec rake", options)
              end
            else
              log("ignore tests for [#{mn_gem}] gem because branch isn't [#{branch_name}]", options)
            end
          end
        end
      end

      def finish(options)
        validate 'finish', options

        branch_name = options[:branch]
        path = options[:gems_path]

        log("merge branch [#{branch_name}] to master", options)

        if yesno("please confirm that all PRs for [#{branch_name}] are 'green'", options)
          leaf_gems = Lapidist.gems(path)
          gem_deps = Lapidist.gem_deps(path)

          leaf_gems.each do |mn_gem|
            gem_project_path = File.join(path, mn_gem.to_s)
            gem_devel_gemfile = File.join(gem_project_path, DEVEL_GEMFILE)

            Dir.chdir(gem_project_path) do
              next unless git_branch_is(branch_name)

              File.delete(gem_devel_gemfile) unless options[:dry_run]

              Bundler.with_clean_env do
                gem_deps[mn_gem].each do |d|
                  run_cmd("bundle config --delete local.#{d} #{File.join(path, d)}", options)
                end

                run_cmd("bundle install", options)
              end

              run_cmd("git add -u #{DEVEL_GEMFILE} Gemfile.lock", options)
              run_cmd("git commit -m \"Feature #{branch_name}\" done", options)
              run_cmd("git push origin #{branch_name}", options)
            end
          end
        else
          puts "[!] please fix all issues before finish [#{branch_name}] branch"
        end
      end

      def release(options)
        validate 'release', options

        leaf_gems = options[:gems]
        version = options[:version]
        path = options[:gems_path]

        log("release #{leaf_gems} gems...", options)

        leaf_gems.each { |mn_gem|
          gem_project_path = File.expand_path(File.join(path, mn_gem.to_s))

          Dir.chdir(gem_project_path) do
            if git_branch_is('master')
              log("do version bump for [#{mn_gem}] gem...", options)
              run_cmd("gem bump --tag --push --release --version #{version}", options)
            else
              raise "Stop release for [#{mn_gem}] gem because current branch isn't [master]"
            end
          end
        }
      end

      @private

      def run_cmd(cmd, options)
        if options[:dry_run] || options[:verbose]
          puts "run system(#{cmd}) pwd:#{Dir.pwd}"
        end

        if !options[:dry_run]
          system(cmd, chdir: Dir.pwd)
        end
      end

      def validate(action, options)
        case action
        when 'start', 'rake', 'finish'
          raise OptionParser::MissingArgument, "Missing -b/--branch [value]" if options[:branch].nil?
          raise OptionParser::MissingArgument, "Missing -p/--gems-path [path]" if options[:gems_path].nil?
        when 'release'
          raise OptionParser::MissingArgument, "Missing -p/--gems-path [path]" if options[:gems_path].nil?
          raise OptionParser::MissingArgument, "Missing -g/--gems [value]" if options[:gems].nil?
          raise OptionParser::MissingArgument, "Missing --version [value]" if options[:version].nil?
        end
      end

      def log(message, options)
        puts "[v] #{message}" if options[:verbose]
      end

      def git_branch_is(branch_name)
        `git branch --show-current`.strip == branch_name
      end

      def yesno(message, options)
        true if options[:silent]
        printf "[?] #{message} - press 'y' to continue: "
        prompt = STDIN.gets.chomp
        return prompt == 'y'
      end
    end
  end
end
