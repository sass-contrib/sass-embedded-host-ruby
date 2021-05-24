# frozen_string_literal: true

require 'bundler/gem_tasks'

task default: :test

desc 'Download dart-sass-embedded'
task :extconf do
  require_relative 'ext/sass_embedded/extconf'
end

desc 'Run all tests'
task :test do
  $LOAD_PATH.unshift('lib', 'test')
  Dir.glob('./test/**/*_test.rb').sort.each { |f| require f }
end
