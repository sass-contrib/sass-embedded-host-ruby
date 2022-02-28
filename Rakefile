# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

ENV['gem_push'] = ENV['CI'] || 'false'

task default: (ENV['CI'] ? [] : %i[rubocop]).concat(%i[compile spec])

desc 'Compile all the extensions'
task :compile do
  raise unless system('make', '-C', 'ext/sass')
end

RSpec::Core::RakeTask.new

RuboCop::RakeTask.new
