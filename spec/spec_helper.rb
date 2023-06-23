# frozen_string_literal: true

require 'sass-embedded'

require 'json'
require_relative 'console'
require_relative 'sandbox'

RSpec.configure do |config|
  config.color_mode = :on if ENV.key?('GITHUB_ACTIONS')
  config.formatter = :documentation

  config.include Console
  config.include Sandbox
end
