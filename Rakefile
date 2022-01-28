# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

ENV['gem_push'] = ENV['CI'] || 'false'

task default: %i[compile rubocop spec test]

desc 'Compile all the extensions'
task :compile do
  system('make', '-C', 'ext/sass')
end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/test_*.rb']
end

RSpec::Core::RakeTask.new

RuboCop::RakeTask.new
