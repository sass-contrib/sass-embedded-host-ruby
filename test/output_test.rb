# frozen_string_literal: true

require_relative 'test_helper'

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

      def test_output_output_style
        data = <<~SCSS
          $var: bang;

          .foo {
            baz: $var;
          }
        SCSS

        assert_equal <<~CSS.chomp, @embedded.render(data: data, output_style: :expanded).css
          .foo {
            baz: bang;
          }
        CSS

        assert_equal <<~CSS.chomp, @embedded.render(data: data, output_style: :compressed).css
          .foo{baz:bang}
        CSS
      end

      def test_output_output_style_argument_error
        assert_raises(ArgumentError) do
          @embedded.render(data: '', output_style: :nested).css
        end

        assert_raises(ArgumentError) do
          @embedded.render(data: '', output_style: :compact).css
        end

        assert_raises(ArgumentError) do
          @embedded.render(data: '', output_style: nil).css
        end
      end

      DATA_INDENT_TEST = <<~SCSS
        @media all {
          .foo {
            baz: bang;
          }
        }
      SCSS

      def test_output_indent_width
        assert_equal <<~CSS.chomp, @embedded.render(data: DATA_INDENT_TEST, indent_width: 0).css
          @media all {
          .foo {
          baz: bang;
          }
          }
        CSS

        assert_equal <<~CSS.chomp, @embedded.render(data: DATA_INDENT_TEST, indent_width: 1).css
          @media all {
           .foo {
            baz: bang;
           }
          }
        CSS

        assert_equal <<~CSS.chomp, @embedded.render(data: DATA_INDENT_TEST, indent_width: 4).css
          @media all {
              .foo {
                  baz: bang;
              }
          }
        CSS
      end

      def test_output_indent_width_range_error
        assert_raises(RangeError) do
          @embedded.render(data: DATA_INDENT_TEST, indent_width: -1).css
        end

        assert_raises(RangeError) do
          @embedded.render(data: DATA_INDENT_TEST, indent_width: 11).css
        end
      end

      def test_output_indent_width_argument_error
        assert_raises(ArgumentError) do
          @embedded.render(data: DATA_INDENT_TEST, indent_width: 3.14).css
        end
      end

      def test_output_indent_type
        assert_equal <<~CSS.chomp, @embedded.render(data: DATA_INDENT_TEST, indent_type: :tab).css
          @media all {
          \t\t.foo {
          \t\t\t\tbaz: bang;
          \t\t}
          }
        CSS

        assert_equal <<~CSS.chomp, @embedded.render(data: DATA_INDENT_TEST, indent_width: 1, indent_type: 'tab').css
          @media all {
          \t.foo {
          \t\tbaz: bang;
          \t}
          }
        CSS
      end

      def test_output_linefeed_default
        data = <<~SCSS
          $var: bang;

          .foo {
            baz: $var;
          }
        SCSS

        assert_equal ".foo {\n  baz: bang;\n}", @embedded.render(data: data).css
        assert_equal ".foo {\n  baz: bang;\n}", @embedded.render(data: data, linefeed: :lf).css
      end

      def test_output_linefeed
        data = <<~SCSS
          $var: bang;

          .foo {
            baz: $var;
          }
        SCSS

        assert_equal ".foo {\n\r  baz: bang;\n\r}", @embedded.render(data: data, linefeed: :lfcr).css
        assert_equal ".foo {\r  baz: bang;\r}", @embedded.render(data: data, linefeed: :cr).css
        assert_equal ".foo {\r\n  baz: bang;\r\n}", @embedded.render(data: data, linefeed: :crlf).css
      end
    end
  end
end
