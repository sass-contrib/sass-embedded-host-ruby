# frozen_string_literal: true

require_relative 'helper'

module Sass
  class Embedded
    class CompileErrorTest < MiniTest::Test
      include TempFileTest

      def setup
        @embedded = Embedded.new
      end

      def teardown
        @embedded.close
      end

      def test_compile_string
        template = <<~SCSS
          .foo {
            baz: bang;
            padding top: 10px;
          }
        SCSS

        @embedded.compile_string(template)
      rescue CompileError => e
        assert_nil e.span.url
        assert_equal 2, e.span.start.line
        assert_equal 19, e.span.start.column
      end

      def test_compile
        temp_file('style.scss', <<~SCSS)
          .foo {
            baz: bang;
            padding top: 10px;
          }
        SCSS

        @embedded.compile('style.scss')
      rescue CompileError => e
        assert_equal 'style.scss', File.basename(e.span.url)
        assert_equal 2, e.span.start.line
        assert_equal 19, e.span.start.column
      end
    end
  end
end
