# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/deprecations.test.ts
RSpec.describe Sass do
  describe 'a warning' do
    it 'is not emitted when deprecation id silenced' do
      stdio = capture_stdio do
        described_class.compile_string(
          'a { $b: c !global; }',
          silence_deprecations: ['new-global']
        )
      end
      expect(stdio.err).to be_empty
    end
  end

  describe 'an error' do
    it 'is thrown when deprecation id made fatal' do
      expect do
        described_class.compile_string(
          'a { $b: c !global; }',
          fatal_deprecations: ['new-global']
        )
      end.to raise_sass_compile_error
    end
  end
end
