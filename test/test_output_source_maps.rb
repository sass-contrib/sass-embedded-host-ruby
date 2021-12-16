# frozen_string_literal: true

require_relative 'helper'

module Sass
  class Embedded
    class SourceMapsTest < MiniTest::Test
      include TempFileTest

      def setup
        @embedded = Embedded.new
      end

      def teardown
        @embedded.close
      end

      def test_no_source_map
        scss = <<~SCSS
          $size: 40px;
          h1 {
            font-size: $size;
          }
        SCSS

        css = <<~CSS.chomp
          h1 {
            font-size: 40px;
          }
        CSS

        temp_file('style.scss', scss)

        result = @embedded.compile('style.scss')
        assert_equal css, result.css
        assert_nil result.source_map
      end

      def test_source_map
        scss = <<~SCSS
          $size: 40px;
          h1 {
            font-size: $size;
          }
        SCSS

        css = <<~CSS.chomp
          h1 {
            font-size: 40px;
          }
        CSS

        temp_file('style.scss', scss)

        result = @embedded.compile('style.scss', source_map: true)
        assert_equal css, result.css
        JSON.parse(result.source_map)
      end
    end
  end
end
