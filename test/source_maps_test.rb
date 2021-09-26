# frozen_string_literal: true

require_relative 'test_helper'

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

        result = @embedded.render(file: 'style.scss')
        assert_equal css, result.css
        assert_nil result.map
      end

      def test_source_map_file_as_string
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

          /*# sourceMappingURL=out.map */
        CSS

        temp_file('style.scss', scss)

        result = @embedded.render(file: 'style.scss',
                                  source_map: 'out.map')
        assert_equal css, result.css
        JSON.parse(result.map)
      end

      def test_source_map_true_without_out_file_has_no_effect
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

        result = @embedded.render(file: 'style.scss',
                                  source_map: true)
        assert_equal css, result.css
        assert_nil result.map
      end

      def test_source_map_true_with_out_file
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

          /*# sourceMappingURL=out.css.map */
        CSS

        temp_file('style.scss', scss)

        result = @embedded.render(file: 'style.scss',
                                  source_map: true,
                                  out_file: 'out.css')
        assert_equal css, result.css
        JSON.parse(result.map)
      end

      def test_omit_source_map_url
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

        result = @embedded.render(file: 'style.scss',
                                  source_map: 'out.map',
                                  omit_source_map_url: true)
        assert_equal css, result.css
        JSON.parse(result.map)
      end

      def test_source_map_embedded
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

          /*# sourceMappingURL=data:application/json;base64,
        CSS

        temp_file('style.scss', scss)

        result = @embedded.render(file: 'style.scss',
                                  source_map: 'out.map',
                                  source_map_embed: true)
        assert result.css.start_with? css
        JSON.parse(result.map)
      end

      def test_source_map_root
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

          /*# sourceMappingURL=out.map */
        CSS

        temp_file('style.scss', scss)

        result = @embedded.render(file: 'style.scss',
                                  source_map: 'out.map',
                                  source_map_root: 'assets')
        assert_equal css, result.css
        assert_equal 'assets', JSON.parse(result.map)['sourceRoot']
      end
    end
  end
end
