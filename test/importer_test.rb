# frozen_string_literal: true

require_relative 'test_helper'

module Sass
  class ImporterTest < MiniTest::Test
    include TempFileTest

    def setup
      @embedded = Embedded.new
    end

    def teardown
      @embedded.close
    end

    def render(data, importer)
      @embedded.render(data: data, importer: importer)[:css]
    end

    def test_custom_importer_works
      temp_file('fonts.scss', '.font { color: $var1; }')

      data = <<~SCSS
        @import "styles";
        @import "fonts";
      SCSS

      output = render(data, [
                        lambda { |url, _prev|
                          { contents: '$var1: #000; .hi { color: $var1; }' } if url =~ /styles/
                        }
                      ])

      assert_equal <<~CSS.chomp, output
        .hi {
          color: #000;
        }

        .font {
          color: #000;
        }
      CSS
    end

    def test_custom_importer_works_with_empty_contents
      output = render("@import 'fake.scss';", [
                        lambda { |_url, _prev|
                          { contents: '' }
                        }
                      ])

      assert_equal '', output
    end

    def test_custom_importer_works_with_file
      temp_file('test.scss', '.test { color: #000; }')

      output = render("@import 'fake.scss';", [
                        lambda { |_url, _prev|
                          { file: File.absolute_path('test.scss') }
                        }
                      ])

      assert_equal <<~CSS.chomp, output
        .test {
          color: #000;
        }
      CSS
    end

    def test_custom_importer_comes_after_local_file
      temp_file('test.scss', '.test { color: #000; }')

      output = render("@import 'test.scss';", [
                        lambda { |_url, _prev|
                          return { contents: '.h1 { color: #fff; }' }
                        }
                      ])

      assert_equal <<~CSS.chomp, output
        .test {
          color: #000;
        }
      CSS
    end

    def test_custom_importer_that_does_not_resolve
      assert_raises(RenderError) do
        render("@import 'test.scss';", [
                 lambda { |_url, _prev|
                 }
               ])
      end
    end

    def test_custom_importer_that_returns_error
      assert_raises(RenderError) do
        render("@import 'test.scss';", [
                 lambda { |_url, _prev|
                   IOError.new 'test error'
                 }
               ])
      end
    end

    def test_custom_importer_that_raises_error
      assert_raises(RenderError) do
        render("@import 'test.scss';", [
                 lambda { |_url, _prev|
                   raise IOError, 'test error'
                 }
               ])
      end
    end

    def test_parent_path_is_accessible
      output = @embedded.render(data: "@import 'parent.scss';",
                                file: 'import-parent-filename.scss',
                                importer: [
                                  lambda { |_url, prev|
                                    { contents: ".#{prev} { color: red; }" }
                                  }
                                ])[:css]

      assert_equal <<~CSS.chomp, output
        .import-parent-filename.scss {
          color: red;
        }
      CSS
    end

    def test_call_embedded_importer
      output = @embedded.render(data: "@import 'parent.scss';",
                                importer: [
                                  lambda { |_url, _prev|
                                    {
                                      contents: @embedded.render(data: "@import 'parent-parent.scss'",
                                                                 importer: [
                                                                   lambda { |_url, _prev|
                                                                     { contents: 'h1 { color: black; }' }
                                                                   }
                                                                 ])[:css]
                                    }
                                  }
                                ])[:css]

      assert_equal <<~CSS.chomp, output
        h1 {
          color: black;
        }
      CSS
    end
  end
end
