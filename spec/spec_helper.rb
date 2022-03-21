# frozen_string_literal: true

require 'sass-embedded'

require 'json'
require_relative './console'
require_relative './sandbox'

RSpec.configure do |config|
  config.formatter = :documentation

  config.include Console
  config.include Sandbox
end
