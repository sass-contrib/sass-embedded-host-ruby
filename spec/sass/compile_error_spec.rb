# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sass::CompileError do
  describe '.to_css' do
    describe 'generates valid css for error message' do
      it 'without quotes' do
        expect { Sass.compile_string('a { b:') }
          .to raise_error(described_class) do |error|
            expect(error.full_message).not_to include('"')
            expect(error.full_message).not_to include("'")
            expect(Sass.compile_string(error.to_css).css).to include(error.message)
          end
      end

      it 'with double quote' do
        expect { Sass.compile_string('a { b: "') }
          .to raise_error(described_class) do |error|
            expect(error.full_message).to include('"')
            expect(error.full_message).not_to include("'")
            expect(Sass.compile_string(error.to_css).css).to include(error.message)
          end
      end

      it 'with single quote' do
        expect { Sass.compile_string("a { b: '") }
          .to raise_error(described_class) do |error|
            expect(error.full_message).to include("'")
            expect(error.full_message).not_to include('"')
            expect(Sass.compile_string(error.to_css).css).to include(error.message)
          end
      end

      it 'with double quote and single quote' do
        expect { Sass.compile_string("a { b: 'c'") }
          .to raise_error(described_class) do |error|
            expect(error.full_message).to include("'")
            expect(error.full_message).to include('"')
            expect(Sass.compile_string(error.to_css).css).to include(error.message)
          end
      end

      it 'with css comment' do
        expect { Sass.compile_string('/* a */ b {') }
          .to raise_error(described_class) do |error|
            expect(error.full_message).to include('/* a */')
            expect(Sass.compile_string(error.to_css).css).to include(error.message)
          end
      end
    end
  end
end
