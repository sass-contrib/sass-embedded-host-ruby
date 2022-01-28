# frozen_string_literal: true

require 'json'
require_relative './console'
require_relative './sandbox'
require_relative '../lib/sass'

RSpec.configure do |config|
  config.formatter = :documentation

  config.include Console
  config.include Sandbox
end
