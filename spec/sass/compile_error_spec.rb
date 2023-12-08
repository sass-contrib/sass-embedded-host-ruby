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

    it 'generates css comment with UTF-8 character set' do
      expect { Sass.compile_string('/* コメント */ a {') }
        .to raise_error(described_class) do |error|
          expect(error.full_message).to include('コメント')
          comment = %r{/\*[^*]*\*+([^/*][^*]*\*+)*/}.match(error.to_css)[0]
          expect(comment).to include('コメント')
        end
    end

    it 'generates css rule with US-ASCII character set' do
      expect { Sass.compile_string('/* コメント */ a {') }
        .to raise_error(described_class) do |error|
          expect(error.full_message).to include('コメント')
          rule = error.to_css.sub(%r{/\*[^*]*\*+([^/*][^*]*\*+)*/}, '')
          expect(rule).not_to include('コメント')
          expect(rule.codepoints).to all(be < 128)
          expect(Sass.compile_string(rule).css).to include('コメント')
        end
    end
  end
end
