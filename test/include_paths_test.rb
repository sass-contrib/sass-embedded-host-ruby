# frozen_string_literal: true

require_relative 'test_helper'

module Sass
  class Embedded
    class IncludePathsTest < MiniTest::Test
      include TempFileTest

      def setup
        @embedded = Embedded.new
      end

      def teardown
        @embedded.close
      end

      def test_include_paths
        temp_dir('included_1')
        temp_dir('included_2')

        temp_file('included_1/import_parent.scss', '$s: 30px;')
        temp_file('included_2/import.scss', "@use 'import_parent' as *; $size: $s;")
        temp_file('styles.scss', "@use 'import.scss' as *; .hi { width: $size; }")

        css = <<~CSS.chomp
          .hi {
            width: 30px;
          }
        CSS

        assert_equal css, @embedded.render(file: 'styles.scss',
                                           include_paths: %w[
                                             included_1 included_2
                                           ]).css
      end

      def test_global_include_paths
        temp_dir('included_1')
        temp_dir('included_2')

        temp_file('included_1/import_parent.scss', '$s: 30px;')
        temp_file('included_2/import.scss', "@use 'import_parent' as *; $size: $s;")
        temp_file('styles.scss', "@use 'import.scss' as *; .hi { width: $size; }")

        ::Sass::Embedded.include_paths << 'included_1'
        ::Sass::Embedded.include_paths << 'included_2'

        css = <<~CSS.chomp
          .hi {
            width: 30px;
          }
        CSS

        assert_equal css, @embedded.render(file: 'styles.scss').css
      end

      def test_include_paths_from_env
        expected_include_paths = %w[included_3 included_4]

        ::Sass::Embedded.instance_eval { @include_paths = nil }

        ENV['SASS_PATH'] = expected_include_paths.join(File::PATH_SEPARATOR)

        assert_equal expected_include_paths, ::Sass::Embedded.include_paths

        ::Sass::Embedded.include_paths.clear
      end

      def test_include_paths_not_configured
        temp_dir('included_5')
        temp_dir('included_6')
        temp_file('included_5/import_parent.scss', '$s: 30px;')
        temp_file('included_6/import.scss', "@use 'import_parent' as *; $size: $s;")
        temp_file('styles.scss', "@use 'import.scss' as *; .hi { width: $size; }")

        assert_raises(RenderError) do
          @embedded.render(file: 'styles.scss')
        end
      end
    end
  end
end
