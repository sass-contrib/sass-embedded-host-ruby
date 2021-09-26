# frozen_string_literal: true

require_relative 'test_helper'

module Sass
  class Embedded
    class InputTest < MiniTest::Test
      include TempFileTest

      def setup
        @embedded = Embedded.new
      end

      def teardown
        @embedded.close
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

        result = @embedded.render(data: scss)
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
        result = @embedded.render(file: 'style.scss')
        assert_equal css, result.css
      end
    end
  end
end
