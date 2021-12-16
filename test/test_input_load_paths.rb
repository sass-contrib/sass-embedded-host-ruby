# frozen_string_literal: true

require_relative 'helper'

module Sass
  class Embedded
    class LoadPathsTest < MiniTest::Test
      include TempFileTest

      def setup
        @embedded = Embedded.new
      end

      def teardown
        @embedded.close
      end

      def test_load_paths
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

        assert_equal css, @embedded.compile('styles.scss',
                                            load_paths: %w[
                                              included_1 included_2
                                            ]).css
      end
    end
  end
end
