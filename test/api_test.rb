# frozen_string_literal: true

require_relative 'test_helper'

module Sass
  class EmbeddedTest < MiniTest::Test
    include TempFileTest

    def setup
      @embedded = Embedded.new
    end

    def teardown
      @embedded.close
    end

    def render(data)
      @embedded.render(data: data)[:css]
    end

    def test_indent_width
      template = <<~SCSS
        @media all {
          .foo {
            baz: bang;
          }
        }
      SCSS

      assert_equal <<~CSS.chomp, @embedded.render(data: template, indent_width: 0)[:css]
        @media all {
        .foo {
        baz: bang;
        }
        }
      CSS

      assert_equal <<~CSS.chomp, @embedded.render(data: template, indent_width: 1)[:css]
        @media all {
         .foo {
          baz: bang;
         }
        }
      CSS

      assert_equal <<~CSS.chomp, @embedded.render(data: template, indent_width: 4)[:css]
        @media all {
            .foo {
                baz: bang;
            }
        }
      CSS

      assert_equal <<~CSS.chomp, @embedded.render(data: template, indent_width: 10)[:css]
        @media all {
                  .foo {
                            baz: bang;
                  }
        }
      CSS
    end

    def test_indent_type
      template = <<~SCSS
        @media all {
          .foo {
            baz: bang;
          }
        }
      SCSS

      assert_equal <<~CSS.chomp, @embedded.render(data: template, indent_type: :tab)[:css]
        @media all {
        \t\t.foo {
        \t\t\t\tbaz: bang;
        \t\t}
        }
      CSS

      assert_equal <<~CSS.chomp, @embedded.render(data: template, indent_width: 1, indent_type: 'tab')[:css]
        @media all {
        \t.foo {
        \t\tbaz: bang;
        \t}
        }
      CSS
    end

    def test_linefeed
      template = <<~SCSS
        .foo {
          baz: bang;
        }
      SCSS

      assert_equal ".foo {\n  baz: bang;\n}", @embedded.render(data: template, linefeed: :lf)[:css]
      assert_equal ".foo {\n\r  baz: bang;\n\r}", @embedded.render(data: template, linefeed: :lfcr)[:css]
      assert_equal ".foo {\r  baz: bang;\r}", @embedded.render(data: template, linefeed: :cr)[:css]
      assert_equal ".foo {\r\n  baz: bang;\r\n}", @embedded.render(data: template, linefeed: :crlf)[:css]
    end
  end
end
