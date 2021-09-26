# frozen_string_literal: true

require_relative 'test_helper'

module Sass
  class Embedded
    class IndentedSyntaxTest < MiniTest::Test
      include TempFileTest

      def setup
        @embedded = Embedded.new
      end

      def teardown
        @embedded.close
      end

      def test_input_data_with_indented_syntax
        sass = <<~SASS
          $size: 30px
          .foo
            width: $size
        SASS

        css = <<~CSS.chomp
          .foo {
            width: 30px;
          }
        CSS

        assert_raises(RenderError) do
          @embedded.render(data: sass)
        end

        assert_raises(RenderError) do
          @embedded.render(data: sass, indented_syntax: false)
        end

        assert_equal css, @embedded.render(data: sass, indented_syntax: true).css
      end

      def test_input_file_with_indented_syntax
        sass = <<~SASS
          $size: 30px
          .foo
            width: $size
        SASS

        css = <<~CSS.chomp
          .foo {
            width: 30px;
          }
        CSS

        temp_file('style.sass', sass)

        assert_equal css, @embedded.render(file: 'style.sass').css
        assert_equal css, @embedded.render(file: 'style.sass', indented_syntax: true).css
        assert_equal css, @embedded.render(file: 'style.sass', indented_syntax: false).css
      end
    end
  end
end
