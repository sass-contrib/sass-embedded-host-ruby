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
  end
end
