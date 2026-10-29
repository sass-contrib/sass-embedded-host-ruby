# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/deprecations.test.ts
RSpec.describe Sass do
  describe 'a warning' do
    it 'is not emitted when deprecation silenced without a list' do
      stdio = capture_stdio do
        described_class.compile_string(
          'a { $b: c !global; }',
          silence_deprecations: 'new-global'
        )
      end
      expect(stdio.err).to be_empty
    end

    it 'is not emitted when deprecation id silenced' do
      stdio = capture_stdio do
        described_class.compile_string(
          'a { $b: c !global; }',
          silence_deprecations: ['new-global']
        )
      end
      expect(stdio.err).to be_empty
    end

    it 'is emitted for an excluded fatal deprecation' do
      fn = double
      allow(fn).to receive(:call) { |_message, options|
        expect(options.deprecation_type).to eq('new-global')
      }

      described_class.compile_string(
        'a { $b: c !global; }',
        fatal_deprecations: {
          include: '1.105.0',
          exclude: 'new-global'
        },
        logger: {
          warn: fn
        }
      )

      expect(fn).to have_received(:call)
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

    it 'is thrown when version made fatal' do
      expect do
        described_class.compile_string(
          'a { $b: c !global; }',
          fatal_deprecations: ['1.17.2']
        )
      end.to raise_sass_compile_error
    end
  end
end
