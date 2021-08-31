# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubocop/rake_task'

ENV['gem_push'] = ENV['CI'] || 'false'

task 'default' => %w[rubocop test]

desc 'Compile all the extensions'
task 'compile' do
  system('make', '-C', 'ext/sass')
end

desc 'Run all the tests'
task 'test' => 'compile' do
  Dir.glob('test/**/*_test.rb').sort.each { |f| require_relative f }
end

RuboCop::RakeTask.new
