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

precision = Sass::Value.const_get(:FuzzyMath)::PRECISION - 1

RSpec::Matchers.matcher :fuzzy_eq do |expected|
  match do |actual|
    case expected
    when Sass::Value::Color
      expect { actual.assert_color }.not_to raise_error
      expect(actual.space).to eq(expected.space)
      expect(actual.channels_or_nil).to fuzzy_match_array(expected.channels_or_nil)
      expect(actual.channel_missing?('alpha')).to eq(expected.channel_missing?('alpha'))
      expect(actual.alpha).to fuzzy_eq(expected.alpha)
    when Numeric
      expect(actual).to be_within(((10**-precision) / 2)).of(expected.round(precision))
    else
      expect(actual).to eq(expected)
    end
  end
end

RSpec::Matchers.matcher :fuzzy_match_array do |expected|
  match do |actual|
    expect(actual).to match_array(expected.map do |obj|
      if obj.is_a?(Numeric)
        a_value_within((10**-precision) / 2).of(obj.round(precision))
      else
        obj
      end
    end)
  end
end
