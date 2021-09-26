# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/sass'

module Sass
  class Embedded
    class RenderTest < MiniTest::Test
      def test_sass_render
        assert_equal '', ::Sass.render(data: '').css

        css = <<~CSS.chomp
          h1 {
            font-size: 2rem;
          }
        CSS

        assert_equal css, ::Sass.render(data: 'h1 { font-size: 2rem; }').css
      end
    end
  end
end
