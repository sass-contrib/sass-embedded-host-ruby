# frozen_string_literal: true

require_relative 'helper'
require_relative '../lib/sass'

module Sass
  class Embedded
    class CompileTest < MiniTest::Test
      include TempFileTest

      def setup
        @embedded = Embedded.new
      end

      def teardown
        @embedded.close
      end

      def test_sass_compile
        assert_equal '', ::Sass.compile_string('').css

        css = <<~CSS.chomp
          h1 {
            font-size: 2rem;
          }
        CSS

        assert_equal css, ::Sass.compile_string('h1 { font-size: 2rem; }').css
      end

      def test_input_data
        scss = <<~SCSS
          $var: bang;

          .foo {
            baz: $var;
          }
        SCSS

        css = <<~CSS.chomp
          .foo {
            baz: bang;
          }
        CSS

        result = @embedded.compile_string(scss)
        assert_equal css, result.css
      end

      def test_input_file
        scss = <<~SCSS
          $var: bang;

          .foo {
            baz: $var;
          }
        SCSS

        css = <<~CSS.chomp
          .foo {
            baz: bang;
          }
        CSS

        temp_file('style.scss', scss)
        result = @embedded.compile('style.scss')
        assert_equal css, result.css
      end
    end
  end
end
