# frozen_string_literal: true

require_relative 'test_helper'

module Sass
  class Embedded
    class RenderErrorTest < MiniTest::Test
      include TempFileTest

      def setup
        @embedded = Embedded.new
      end

      def teardown
        @embedded.close
      end

      def test_first_backtrace_is_stdin
        template = <<~SCSS
          .foo {
            baz: bang;
            padding top: 10px;
          }
        SCSS

        @embedded.render(data: template)
      rescue RenderError => e
        expected = 'stdin:3:20'
        assert_equal expected, e.backtrace.first
      end

      def test_first_backtrace_is_file
        temp_file('style.scss', <<~SCSS)
          .foo {
            baz: bang;
            padding top: 10px;
          }
        SCSS

        @embedded.render(file: 'style.scss')
      rescue RenderError => e
        assert e.backtrace.first.end_with? '/style.scss:3:20'
      end
    end
  end
end
