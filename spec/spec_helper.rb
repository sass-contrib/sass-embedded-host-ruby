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

RSpec::Matchers.matcher :raise_sass_compile_error do
  match do |actual|
    expect { actual.call }
      .to raise_error do |error|
        expect(error).to be_a(Sass::CompileError)
        expect(error.span.start.line).to eq(@line) if defined?(@line)
        expect(error.span.url).to eq(@url) if defined?(@url)
        expect(error.message).to include(@message) if defined?(@message)
      end
  end

  chain :with_message do |message|
    @message = message
  end

  chain :with_line do |line|
    @line = line
  end

  chain :with_url do |url|
    @url = url
  end

  chain :without_url do
    @url = nil
  end

  supports_block_expectations
end
