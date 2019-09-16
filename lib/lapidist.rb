require "pathname"
require "rubygems/commands/dependency_command"

module Lapidist
  class Error < StandardError; end

  def self.gems(path, branch_name=nil)
    if File.exist?(path)
      @gems ||= Pathname.new(path).children
        .select { |child|
          child.directory? && (child + ".git").directory? && !child.glob("*.gemspec").empty?
        }
        .select { |child|
          true if branch_name.nil?
          self.git_branch_is child, branch_name
        }
        .map { |e| File.basename(e) }
    else
      raise "#{gitmodules_path} not found make sure that -p/--gems-path correctly specified"
    end
  end

  def self.gem_deps(path, gems)
    @gem_deps ||= gems.map { |g|
      deps = []
      begin
        gemspec_path = File.join(path, g, "#{g}.gemspec")
        deps = File.open(File.join(path, g, "#{g}.gemspec"), 'r:UTF-8').each_line.map { |line|
          line.match(/add_(development_|runtime_)?dependency\s+.([\w_-]+)/)
        }.compact.map { |m| m[2]}.keep_if { |d| gems.include?(d) && keep_gems.include?(d) }.uniq
      rescue Errno::ENOENT => e
        puts "[!] gemspec #{gemspec_path} not found for #{g} gem"
      end

      deps ||= []
      
      [g, deps]
    }.to_h
  end

  def self.gem_tests(path)
    # https://stackoverflow.com/q/28655221/902217
    @gem_tests ||= self.gem_deps(path).inject(Hash.new([])) { |memo, (key, values)|
      values.each { |value| memo[value] += [key] }
      memo
    }
  end

  @private

  def self.git_branch_is(repo_path, branch_name)
    `git -C #{repo_path} branch --show-current`.strip == branch_name
  end
end
