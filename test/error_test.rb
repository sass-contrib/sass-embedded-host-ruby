# frozen_string_literal: true

require_relative "test_helper"

module Sass
  class ErrorTest < MiniTest::Test

    def setup
      @compiler = Embedded::Compiler.new
    end

    def teardown
    end

    def test_first_backtrace_is_sass
      begin
        template = <<-SCSS
.foo {
  baz: bang;
  padding top: 10px;
}
      SCSS

        @compiler.render({
          data: template,
        })
      rescue Sass::CompilationError => err
        expected = "stdin:3:20"
        assert_equal expected, err.backtrace.first
      end
    end
  end
end
