# frozen_string_literal: true

require_relative 'test_helper'

module Sass
  class OutputStyleTest < MiniTest::Test
    def setup
      @compiler = Embedded::Compiler.new
    end

    def teardown; end

    def input_scss
      input_scss = <<~CSS
        $color: #fff;

        #main {
          color: $color;
          background-color: #000;
          p {
            width: 10em;
          }
        }

        .huge {
          font-size: 10em;
          font-weight: bold;
          text-decoration: underline;
        }
      CSS
    end

    def expected_expanded_output
      <<~CSS.chomp
        #main {
          color: #fff;
          background-color: #000;
        }
        #main p {
          width: 10em;
        }

        .huge {
          font-size: 10em;
          font-weight: bold;
          text-decoration: underline;
        }
      CSS
    end

    def test_expanded_output_is_default
      output = @compiler.render({ data: input_scss })[:css]
      assert_equal expected_expanded_output, output
    end

    def test_output_style_accepts_strings
      output = @compiler.render({ data: input_scss, output_style: :expanded })[:css]
      assert_equal expected_expanded_output, output
    end

    def test_invalid_output_style
      assert_raises(InvalidStyleError) do
        @compiler.render({ data: input_scss, output_style: :totally_wrong })[:css]
      end
    end

    def test_unsupported_output_style
      assert_raises(UnsupportedValue) do
        @compiler.render({ data: input_scss, output_style: :nested })[:css]
      end

      assert_raises(UnsupportedValue) do
        @compiler.render({ data: input_scss, output_style: :compact })[:css]
      end
    end

    def test_compressed_output
      output = @compiler.render({ data: input_scss, output_style: :compressed })[:css]
      assert_equal <<~CSS.chomp, output
        #main{color:#fff;background-color:#000}#main p{width:10em}.huge{font-size:10em;font-weight:bold;text-decoration:underline}
      CSS
    end

    def test_string_output_style_names
      output = @compiler.render({ data: input_scss, output_style: 'compressed' })[:css]
      assert_equal <<~CSS.chomp, output
        #main{color:#fff;background-color:#000}#main p{width:10em}.huge{font-size:10em;font-weight:bold;text-decoration:underline}
      CSS
    end
  end
end
