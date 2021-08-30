# frozen_string_literal: true

require 'bundler/gem_tasks'

task 'default' => %w[rubocop test]

desc 'Compile all the extensions'
task 'compile' do
  system('make', '-C', 'ext/sass')
end

desc 'Run all the tests'
task 'test' => 'compile' do
  Dir.glob('test/**/*_test.rb').sort.each { |f| require_relative f }
end

task 'release', [:remote] => ['build', 'release:guard_clean', 'release:source_control_push']

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  nil
end
