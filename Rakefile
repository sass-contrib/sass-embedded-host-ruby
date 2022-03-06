# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

ENV['gem_push'] = ENV['CI'] || 'false'

task default: %i[rubocop compile spec]

desc 'Compile all the extensions'
task :compile do
  sh 'rake', '-C', 'ext/sass', 'install'
end

RSpec::Core::RakeTask.new

RuboCop::RakeTask.new
