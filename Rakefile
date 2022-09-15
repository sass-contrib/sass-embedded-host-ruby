# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: %i[rubocop compile spec]

desc 'Compile all the extensions'
task :compile do
  sh 'rake', '-C', 'ext/sass', 'clobber', 'install'

  if ENV.key?('ext_platform')
    host_cpu, host_os = ENV['ext_platform'].split('-', 2)

    rm 'ext/sass/embedded.rb'
    rm_rf 'ext/sass/sass_embedded'

    sh 'rake', '-C', 'ext/sass',
       '-E', "RbConfig::CONFIG.merge!({ 'host_cpu' => #{host_cpu.dump}, 'host_os' => #{host_os.dump} })", 'embedded.rb'
  end
end

RSpec::Core::RakeTask.new

RuboCop::RakeTask.new
