# frozen_string_literal: true

require_relative 'helper'

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

        assert_raises(CompileError) do
          @embedded.compile_string(sass)
        end

        assert_raises(CompileError) do
          @embedded.compile_string(sass, syntax: :scss)
        end

        assert_equal css, @embedded.compile_string(sass, syntax: :indented).css
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

        assert_equal css, @embedded.compile('style.sass').css
      end
    end
  end
end
