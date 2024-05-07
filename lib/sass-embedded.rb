#!/usr/bin/env ruby
# frozen_string_literal: true

spec = Gem.loaded_specs['sass-embedded']
platform = spec&.platform
if platform.is_a?(Gem::Platform) && platform.os == 'linux' && platform.version.nil?
  update = if Gem.disable_system_update_message
             'updating Ruby to version 3.2 or later'
           else
             "running 'gem update --system' to update RubyGems"
           end
  install = if defined?(Bundler)
              "running 'rm -f Gemfile.lock && bundle install'"
            else
              "running 'gem install sass-embedded'"
            end
  raise LoadError, "The gemspec for #{spec.name} at #{spec.loaded_from} was broken. " \
                   "Try #{update}, and then try #{install} to reinstall."
end

require_relative 'sass/embedded'
