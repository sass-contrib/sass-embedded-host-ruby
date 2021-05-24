# frozen_string_literal: true

require_relative 'test_helper'

module Sass
  class ErrorTest < MiniTest::Test
    def setup
      @embedded = Embedded.new
    end

    def teardown
      @embedded.close
    end

    def test_first_backtrace_is_sass
      template = <<~SCSS
        .foo {
          baz: bang;
          padding top: 10px;
        }
      SCSS

      @embedded.render({
                         data: template
                       })
    rescue Sass::CompilationError => e
      expected = 'stdin:3:20'
      assert_equal expected, e.backtrace.first
    end
  end
end
