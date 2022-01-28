# frozen_string_literal: true

require_relative 'helper'

module Sass
  class Embedded
    class ImporterTest < MiniTest::Test
      include TempFileTest

      class MockImporter
        def initialize(predicate, data)
          @predicate = predicate
          @data = data
        end

        def canonicalize(url, **_kwargs)
          path = Url.file_url_to_path(url)
          Embedded::Url.path_to_file_url(File.absolute_path(path)) if @predicate.call(path)
        end

        def load(canonical_url)
          ImporterResult.new(@data, :scss) if @predicate.call(canonical_url)
        end
      end

      class MockFileImporter
        def initialize(find)
          @find = find
        end

        def find_file_url(url, from_import:) # rubocop:disable Lint/UnusedMethodArgument
          path = Url.file_url_to_path(url)
          Embedded::Url.path_to_file_url(File.absolute_path(@find.call(path)))
        end
      end

      def setup
        @embedded = Embedded.new
      end

      def teardown
        @embedded.close
      end

      def render(data, importer); end

      def test_custom_importer_works
        data = <<~SCSS
          @import "styles";
        SCSS

        importer = MockImporter.new(->(url) { /styles/.match?(url) }, '$var1: #000; .hi { color: $var1; }')
        output = @embedded.compile_string(data, url: Embedded::Url.path_to_file_url('test.scss'),
                                                importer: importer).css

        assert_equal <<~CSS.chomp, output
          .hi {
            color: #000;
          }
        CSS
      end

      def test_custom_importer_works_with_empty_contents
        importer = MockImporter.new(->(_) { true }, '')
        output = @embedded.compile_string("@import 'fake.scss';", url: Embedded::Url.path_to_file_url('test.scss'),
                                                                  importer: importer).css

        assert_equal '', output
      end

      def test_custom_importer_works_with_file
        temp_file('fonts.scss', '.font { color: #000; }')

        importer = MockFileImporter.new(lambda { |path|
          'fonts.scss' if File.basename(path) == 'fake.scss'
        })
        output = @embedded.compile_string("@import 'fake.scss';", url: Embedded::Url.path_to_file_url('test.scss'),
                                                                  importers: [importer]).css

        assert_equal <<~CSS.chomp, output
          .font {
            color: #000;
          }
        CSS
      end

      def test_custom_importer_that_does_not_resolve
        importer = MockImporter.new(->(_) { false }, nil)

        assert_raises(CompileError) do
          @embedded.compile_string("@import 'test.scss';", url: Embedded::Url.path_to_file_url('test.scss'),
                                                           importer: importer).css
        end
      end

      def test_custom_importer_that_raises_error
        importer = MockImporter.new(->(_) { raise IOError, 'test error' }, nil)

        assert_raises(CompileError) do
          @embedded.compile_string("@import 'test.scss';", importer: importer).css
        end
      end
    end
  end
end
