# frozen_string_literal: true

require 'bundler/gem_tasks'

task default: %i[rubocop test]

desc 'Download dart-sass-embedded'
task :extconf do
  system('make', '-C', 'ext')
end

desc 'Run all tests'
task test: :extconf do
  Dir.glob('./test/**/*_test.rb').sort.each { |f| require f }
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  nil
end
