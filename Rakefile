require 'rubygems'
require 'bundler/setup'
require 'rake/rdoctask'
require 'rspec'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

task :default => [:spec]

desc "Flog all"
task :flog do
  system("find all lib -name \\*.rb|xargs flog")
end

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'test/**/*_spec.rb'
  t.verbose = true
  t.rspec_opts = ["-fs", "--color"]
end

desc 'Generate RDoc'
Rake::RDocTask.new do |task|
  task.main = 'README'
  task.title = 'xample'
  task.rdoc_dir = 'doc'
  task.options << "--line-numbers" << "--inline-source"
  task.rdoc_files.include('README', 'lib/**/*.rb')
end
