# frozen_string_literal: true

require_relative 'helper'

module Sass
  class Embedded
    class OutputTest < MiniTest::Test
      include TempFileTest

      def setup
        @embedded = Embedded.new
      end

      def teardown
        @embedded.close
      end

      def test_output_style
        data = <<~SCSS
          $var: bang;

          .foo {
            baz: $var;
          }
        SCSS

        assert_equal <<~CSS.chomp, @embedded.compile_string(data, style: :expanded).css
          .foo {
            baz: bang;
          }
        CSS

        assert_equal <<~CSS.chomp, @embedded.compile_string(data, style: :compressed).css
          .foo{baz:bang}
        CSS
      end

      def test_output_style_argument_error
        assert_raises(ArgumentError) do
          @embedded.compile_string('', style: :nested).css
        end

        assert_raises(ArgumentError) do
          @embedded.compile_string('', style: :compact).css
        end

        assert_raises(ArgumentError) do
          @embedded.compile_string('', style: nil).css
        end
      end
    end
  end
end
