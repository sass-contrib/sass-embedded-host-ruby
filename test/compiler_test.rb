# frozen_string_literal: true

require_relative 'test_helper'

module Sass
  class CompilerTest < MiniTest::Test
    include TempFileTest

    def setup
      @compiler = Embedded::Compiler.new
    end

    def teardown
      @compiler.close
    end

    def render(data)
      @compiler.render({ data: data })[:css]
    end

    def test_line_comments
      skip 'not supported'

      template = <<~SCSS
        .foo {
          baz: bang; }
      SCSS
      expected_output = <<~CSS
        /* line 1, stdin */
        .foo {
          baz: bang;
        }
      CSS
      output = @compiler.render({
                                  data: template,
                                  source_comments: true
                                })
      assert_equal expected_output, output[:css]
    end

    def test_one_line_comments
      assert_equal <<~CSS.chomp, render(<<~SCSS)
        .foo {
          baz: bang;
        }
      CSS
        .foo {// bar: baz;}
          baz: bang; //}
        }
      SCSS
      assert_equal <<~CSS.chomp, render(<<~SCSS)
        .foo bar[val="//"] {
          baz: bang;
        }
      CSS
        .foo bar[val="//"] {
          baz: bang; //}
        }
      SCSS
    end

    def test_variables
      assert_equal <<~CSS.chomp, render(<<~SCSS)
        blat {
          a: foo;
        }
      CSS
                $var: foo;
        #{'        '}
                blat {a: $var}
      SCSS

      assert_equal <<~CSS.chomp, render(<<~SCSS)
        foo {
          a: 2;
          b: 6;
        }
      CSS
        foo {
          $var: 2;
          $another-var: 4;
          a: $var;
          b: $var + $another-var;}
      SCSS
    end

    def test_precision
      skip 'not supported'

      template = <<~SCSS
        $var: 1;
        .foo {
          baz: $var / 3; }
      SCSS
      expected_output = <<~CSS.chomp
        .foo {
          baz: 0.33333333;
        }
      CSS
      output = @compiler.render({
                                  data: template,
                                  precision: 8
                                })
      assert_equal expected_output, output
    end

    def test_precision_not_specified
      template = <<~SCSS
        $var: 1;
        .foo {
          baz: $var / 3; }
      SCSS
      expected_output = <<~CSS.chomp
        .foo {
          baz: 0.3333333333;
        }
      CSS
      output = render(template)
      assert_equal expected_output, output
    end

    def test_source_map
      temp_dir('admin')

      temp_file('admin/text-color.scss', <<~SCSS)
        p {
          color: red;
        }
      SCSS
      temp_file('style.scss', <<~SCSS)
                @use 'admin/text-color';
        #{'        '}
                p {
                  padding: 20px;
                }
      SCSS
      output = @compiler.render({
                                  data: File.read('style.scss'),
                                  source_map: 'style.scss.map'
                                })

      assert output[:map].start_with? '{"version":3,'
    end

    def test_no_source_map
      output = @compiler.render({
                                  data: '$size: 30px;'
                                })
      assert_equal '', output[:map]
    end

    def test_include_paths
      temp_dir('included_1')
      temp_dir('included_2')

      temp_file('included_1/import_parent.scss', '$s: 30px;')
      temp_file('included_2/import.scss', "@use 'import_parent' as *; $size: $s;")
      temp_file('styles.scss', "@use 'import.scss' as *; .hi { width: $size; }")

      assert_equal ".hi {\n  width: 30px;\n}", @compiler.render({
                                                                  data: File.read('styles.scss'),
                                                                  include_paths: %w[
                                                                    included_1 included_2
                                                                  ]
                                                                })[:css]
    end

    def test_global_include_paths
      temp_dir('included_1')
      temp_dir('included_2')

      temp_file('included_1/import_parent.scss', '$s: 30px;')
      temp_file('included_2/import.scss', "@use 'import_parent' as *; $size: $s;")
      temp_file('styles.scss', "@use 'import.scss' as *; .hi { width: $size; }")

      ::Sass.include_paths << 'included_1'
      ::Sass.include_paths << 'included_2'

      assert_equal ".hi {\n  width: 30px;\n}", render(File.read('styles.scss'))
    end

    def test_env_include_paths
      expected_include_paths = %w[included_3 included_4]

      ::Sass.instance_eval { @include_paths = nil }

      ENV['SASS_PATH'] = expected_include_paths.join(File::PATH_SEPARATOR)

      assert_equal expected_include_paths, Sass.include_paths

      ::Sass.include_paths.clear
    end

    def test_include_paths_not_configured
      temp_dir('included_5')
      temp_dir('included_6')
      temp_file('included_5/import_parent.scss', '$s: 30px;')
      temp_file('included_6/import.scss', "@use 'import_parent' as *; $size: $s;")
      temp_file('styles.scss', "@use 'import.scss' as *; .hi { width: $size; }")

      assert_raises(CompilationError) do
        render(File.read('styles.scss'))
      end
    end

    def test_sass_variation
      sass = <<~SASS
        $size: 30px
        .foo
          width: $size
      SASS

      css = <<~CSS.chomp
        .foo {
          width: 30px;
        }
      CSS

      assert_equal css, @compiler.render({ data: sass, indented_syntax: true })[:css]
      assert_raises(CompilationError) do
        @compiler.render({ data: sass, indented_syntax: false })
      end
    end

    def test_inline_source_maps
      skip 'not supported'

      template = <<~SCSS
        .foo {
          baz: bang; }
      SCSS

      output = @compiler.render({
                                  data: template,
                                  source_map: '.',
                                  source_map_embed: true,
                                  source_map_contents: true
                                })[:css]

      assert_match(/sourceMappingURL/, output)
      assert_match(/.foo/, output)
    end

    def test_empty_template
      output = render('')
      assert_equal '', output
    end

    def test_import_plain_css
      temp_file('test.css', '.something{color: red}')
      expected_output = <<~CSS.chomp
        .something {
          color: red;
        }
      CSS

      output = render("@use 'test';")
      assert_equal expected_output, output
    end

    def test_concurrency
      10.times do
        threads = []
        10.times do |i|
          threads << Thread.new(i) do |id|
            output = @compiler.render({
                                        data: "div { width: #{id} }"
                                      })[:css]
            assert_match(/#{id}/, output)
          end
        end
        threads.each(&:join)
      end
    end
  end
end
