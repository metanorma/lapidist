require "pathname"
require "rubygems/commands/dependency_command"

module Lapidist
  DEVEL_GEMFILE = 'Gemfile.devel'

  class Error < StandardError; end

  def self.gems(path, branch_name=nil)
    if File.exist?(path)
      @gems ||= Pathname.new(path).children
        .select { |child|
          child.directory? && (child + ".git").directory? && !child.glob("*.gemspec").empty?
        }
        .select { |child|
          true if branch_name.nil?
          self.git_branch_is branch_name, child
        }
        .map { |e| File.basename(e) }
    else
      raise "#{gitmodules_path} not found make sure that -p/--gems-path correctly specified"
    end
  end

  def self.gem_deps(path, gems)
    @gem_deps ||= gems.map { |g|
      deps = []
      warn g
      gemspec_path = (Pathname.new(path) / g).glob("*.gemspec").first

      if gemspec_path.exist?
        deps = File.open(gemspec_path, 'r:UTF-8').each_line.map { |line|
          line.match(/add_(development_|runtime_)?dependency\s+.([\w_-]+)/)
        }.compact.map { |m| m[2]}.keep_if { |d| gems.include?(d) }.uniq
      else
        self.warn "gemspec #{gemspec_path} not found for #{g} gem"
      end

      deps ||= []

      [g, deps]
    }.to_h
  end

  def self.run_cmd(cmd, options)
    if options[:dry_run] || options[:verbose]
      puts "run system(#{cmd}) pwd:#{Dir.pwd}" 
    end

    if !options[:dry_run]
      IO.popen(cmd, "r+", external_encoding: "UTF-8") do |io|
        io.close_write
        puts io.read
      end
    end
  end

  def self.log(message, options={})
    puts "[v] #{message}" if options[:verbose]
  end

  def self.warn(message, options={})
    puts "[!] #{message}"
  end

  def self.yesno(message, options)
    return true if options[:silent]
    return false if options[:deny]
    printf "[?] #{message} - press 'y' to continue: "
    prompt = STDIN.gets.chomp
    return prompt == 'y'
  end

  def self.gem_repo_path_with_opts(gemname, org)
    ":github => '#{org}/#{gemname}'"
  end

  def self.gem_git_remote_source(remote)
    ":git => '#{remote}'"
  end

  def self.repo_path
    `git -C #{repo_path} config --get remote.origin.url`
  end

  def self.git_branch_is(branch_name, repo_path = '.')
    `git -C #{repo_path} symbolic-ref --short HEAD`.strip == branch_name
  end
end
