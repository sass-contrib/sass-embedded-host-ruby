# frozen_string_literal: true

require_relative 'test_helper'

module Sass
  class SassTest < MiniTest::Test
    def test_sass_works
      assert_equal '', ::Sass.render(data: '')[:css]

      css = <<~CSS.chomp
        h1 {
          font-size: 2rem;
        }
      CSS
      assert_equal css, ::Sass.render(data: 'h1 { font-size: 2rem; }')[:css]
    end
  end
end
