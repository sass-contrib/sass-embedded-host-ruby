# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sass do
  describe '.compile_string' do
    describe 'success' do
      describe 'input' do
        it 'compiles SCSS by default' do
          expect(described_class.compile_string('$a: b; c {d: $a}').css)
            .to eq("c {\n  d: b;\n}")
        end

        it 'compiles SCSS with explicit syntax' do
          expect(described_class.compile_string('$a: b; c {d: $a}', syntax: :scss).css)
            .to eq("c {\n  d: b;\n}")
        end

        it 'compiles indented syntax with explicit syntax' do
          expect(described_class.compile_string("a\n  b: c", syntax: :indented).css)
            .to eq("a {\n  b: c;\n}")
        end

        it 'compiles plain CSS syntax with explicit syntax' do
          expect(described_class.compile_string('a {b: c}', syntax: :css).css)
            .to eq("a {\n  b: c;\n}")
        end

        it "doesn't take its syntax from the URL's extension" do
          # Shouldn't parse the file as the indented syntax.
          expect(described_class.compile_string('a {b: c}', url: 'file:///foo.sass').css)
            .to eq("a {\n  b: c;\n}")
        end
      end

      describe 'loaded_urls' do
        it 'is empty with no URL' do
          expect(described_class.compile_string('a {b: c}').loaded_urls)
            .to eq([])
        end

        it 'contains the URL if one is passed' do
          url = 'file:///foo.scss'
          expect(described_class.compile_string('a {b: c}', url: url).loaded_urls)
            .to eq([url])
        end

        it 'contains an immediate dependency' do
          sandbox do |dir|
            url = dir.url('input.scss')
            dir.write({ '_other.scss' => 'a {b: c}' })
            expect(described_class.compile_string('@use "other"', url: url).loaded_urls)
              .to eq([
                       url,
                       dir.url('_other.scss')
                     ])
          end
        end

        it 'contains a transitive dependency' do
          sandbox do |dir|
            url = dir.url('input.scss')
            dir.write({
                        '_midstream.scss' => '@use "upstream"',
                        '_upstream.scss' => 'a {b: c}'
                      })
            expect(described_class.compile_string('@use "midstream"', url: url).loaded_urls)
              .to eq([
                       url,
                       dir.url('_midstream.scss'),
                       dir.url('_upstream.scss')
                     ])
          end
        end

        describe 'contains a dependency only once' do
          it 'for @use' do
            sandbox do |dir|
              url = dir.url('input.scss')
              dir.write({
                          '_left.scss' => '@use "upstream"',
                          '_right.scss' => '@use "upstream"',
                          '_upstream.scss' => 'a {b: c}'
                        })
              expect(described_class.compile_string('@use "left"; @use "right"', url: url).loaded_urls)
                .to eq([
                         url,
                         dir.url('_left.scss'),
                         dir.url('_upstream.scss'),
                         dir.url('_right.scss')
                       ])
            end
          end

          it 'for @import' do
            sandbox do |dir|
              url = dir.url('input.scss')
              dir.write({
                          '_left.scss' => '@import "upstream"',
                          '_right.scss' => '@import "upstream"',
                          '_upstream.scss' => 'a {b: c}'
                        })
              expect(described_class.compile_string('@import "left"; @import "right"', url: url).loaded_urls)
                .to eq([
                         url,
                         dir.url('_left.scss'),
                         dir.url('_upstream.scss'),
                         dir.url('_right.scss')
                       ])
            end
          end
        end
      end

      it 'url is used to resolve relative loads' do
        sandbox do |dir|
          dir.write({ 'foo/bar/_other.scss' => 'a {b: c}' })

          expect(described_class.compile_string('@use "other"', url: dir.url('foo/bar/style.scss')).css)
            .to eq("a {\n  b: c;\n}")
        end
      end

      describe 'load_paths' do
        it 'is used to resolve loads' do
          sandbox do |dir|
            dir.write({ 'foo/bar/_other.scss' => 'a {b: c}' })

            expect(described_class.compile_string('@use "other"', load_paths: [dir.path('foo/bar')]).css)
              .to eq("a {\n  b: c;\n}")
          end
        end

        it 'resolves relative paths' do
          sandbox do |dir|
            dir.write({ 'foo/bar/_other.scss' => 'a {b: c}' })

            expect(described_class.compile_string('@use "bar/other"', load_paths: [dir.path('foo')]).css)
              .to eq("a {\n  b: c;\n}")
          end
        end

        it "resolves loads using later paths if earlier ones don't match" do
          sandbox do |dir|
            dir.write({ 'baz/_other.scss' => 'a {b: c}' })

            expect(described_class.compile_string('@use "other";',
                                                  load_paths: [dir.path('foo'), dir.path('bar'), dir.path('baz')]).css)
              .to eq("a {\n  b: c;\n}")
          end
        end

        it "doesn't take precedence over loads relative to the url" do
          sandbox do |dir|
            dir.write({
                        'url/_other.scss' => 'a {b: url}',
                        'load-path/_other.scss' => 'a {b: load path}'
                      })

            expect(described_class.compile_string('@use "other";', load_paths: [dir.path('load-path')],
                                                                   url: dir.url('url/input.scss')).css)
              .to eq("a {\n  b: url;\n}")
          end
        end

        it 'uses earlier paths in preference to later ones' do
          sandbox do |dir|
            dir.write({
                        'earlier/_other.scss' => 'a {b: earlier}',
                        'later/_other.scss' => 'a {b: later}'
                      })

            expect(described_class.compile_string('@use "other";',
                                                  load_paths: [dir.path('earlier'), dir.path('later')]).css)
              .to eq("a {\n  b: earlier;\n}")
          end
        end
      end

      it 'recognizes the expanded output style' do
        expect(described_class.compile_string('a {b: c}', style: 'expanded').css)
          .to eq("a {\n  b: c;\n}")
      end

      describe 'source_map' do
        it "doesn't include one by default" do
          expect(described_class.compile_string('a {b: c}').source_map).to be_nil
        end

        it 'includes one if source_map is true' do
          result = described_class.compile_string('a {b: c}', source_map: true)
          expect(result.source_map).not_to be_nil

          # Explicitly don't test the details of the source map, because
          # individual implementations are allowed to generate a custom map.
          source_map = JSON.parse(result.source_map)
          expect(source_map['version']).to be_a(Integer)
          expect(source_map['sources']).to be_a(Array)
          expect(source_map['names']).to be_a(Array)
          expect(source_map['mappings']).to be_a(String)
        end

        it 'includes one with source content if source_map_include_sources is true' do
          result = described_class.compile_string('a {b: c}', source_map: true,
                                                              source_map_include_sources: true)
          expect(result.source_map).not_to be_nil

          source_map = JSON.parse(result.source_map)
          expect(source_map).to have_key('sourcesContent')
          expect(source_map['sourcesContent']).to be_a(Array)
          expect(source_map['sourcesContent']).not_to be_empty
        end
      end
    end

    describe 'error' do
      it 'requires plain CSS with explicit syntax' do
        expect { described_class.compile_string('$a: b; c {d: $a}', syntax: 'css') }
          .to raise_error do |error|
            expect(error).to be_a(Sass::CompileError)
            expect(error.span.start.line).to eq(0)
            expect(error.span.url).to be_nil
          end
      end

      it 'relative loads fail without a URL' do
        sandbox do |dir|
          dir.write({ 'other.scss' => 'a {b: c}' })
          expect { described_class.compile_string('@use "other";') }
            .to raise_error do |error|
              expect(error).to be_a(Sass::CompileError)
              expect(error.span.start.line).to eq(0)
              expect(error.span.url).to be_nil
            end
        end
      end

      describe 'includes source span information' do
        it 'in syntax errors' do
          sandbox do |dir|
            url = dir.url('foo.scss')
            expect { described_class.compile_string('a {b:', url: url) }
              .to raise_error do |error|
                expect(error).to be_a(Sass::CompileError)
                expect(error.span.start.line).to eq(0)
                expect(error.span.url).to eq(url)
              end
          end
        end

        it 'in runtime errors' do
          sandbox do |dir|
            url = dir.url('foo.scss')
            expect { described_class.compile_string('@error "oh no"', url: url) }
              .to raise_error do |error|
                expect(error).to be_a(Sass::CompileError)
                expect(error.span.start.line).to eq(0)
                expect(error.span.url).to eq(url)
              end
          end
        end
      end

      it 'throws an error for an unrecognized style' do
        expect { described_class.compile_string('a {b: c}', style: 'unrecognized style') }
          .to raise_error(ArgumentError)
      end

      it "doesn't throw a Sass exception for an argument error" do
        expect { described_class.compile_string('a {b: c}', style: 'unrecognized style') }
          .to raise_error do |error|
            expect(error).not_to be_a(Sass::CompileError)
          end
      end

      it 'is an instance of StandardError' do
        expect { described_class.compile_string('a {b:') }
          .to raise_error(StandardError)
      end
    end
  end

  describe '.compile' do
    describe 'success' do
      it 'compiles SCSS for a .scss file' do
        sandbox do |dir|
          dir.write({ 'input.scss' => '$a: b; c {d: $a}' })
          expect(described_class.compile(dir.path('input.scss')).css)
            .to eq("c {\n  d: b;\n}")
        end
      end

      it 'compiles SCSS for a file with an unknown extension' do
        sandbox do |dir|
          dir.write({ 'input.asdf' => '$a: b; c {d: $a}' })
          expect(described_class.compile(dir.path('input.asdf')).css)
            .to eq("c {\n  d: b;\n}")
        end
      end

      it 'compiles indented syntax for a .sass file' do
        sandbox do |dir|
          dir.write({ 'input.sass' => "a\n  b: c" })
          expect(described_class.compile(dir.path('input.sass')).css)
            .to eq("a {\n  b: c;\n}")
        end
      end

      it 'compiles plain CSS for a .css file' do
        sandbox do |dir|
          dir.write({ 'input.css' => 'a {b: c}' })
          expect(described_class.compile(dir.path('input.css')).css)
            .to eq("a {\n  b: c;\n}")
        end
      end

      describe 'loaded_urls' do
        it "includes a relative path's URL" do
          sandbox do |dir|
            dir.write({ 'input.scss' => 'a {b: c}' })
            expect(described_class.compile(dir.path('input.scss')).loaded_urls)
              .to eq([dir.url('input.scss')])
          end
        end

        it "includes an absolute path's URL" do
          sandbox do |dir|
            path = File.absolute_path(dir.path('input.scss'))
            dir.write({ 'input.scss' => 'a {b: c}' })
            expect(described_class.compile(path).loaded_urls)
              .to eq([dir.url('input.scss')])
          end
        end

        it 'contains a dependency' do
          sandbox do |dir|
            dir.write({
                        'input.scss' => '@use "other"',
                        '_other.scss' => 'a {b: c}'
                      })
            expect(described_class.compile(dir.path('input.scss')).loaded_urls)
              .to eq([
                       dir.url('input.scss'),
                       dir.url('_other.scss')
                     ])
          end
        end
      end

      it 'the path is used to resolve relative loads' do
        sandbox do |dir|
          dir.write({
                      'foo/bar/input.scss' => '@use "other"',
                      'foo/bar/_other.scss' => 'a {b: c}'
                    })

          expect(described_class.compile(dir.path('foo/bar/input.scss')).css)
            .to eq("a {\n  b: c;\n}")
        end
      end

      describe 'load_paths' do
        it 'is used to resolve loads' do
          sandbox do |dir|
            dir.write({
                        'input.scss' => '@use "other"',
                        'foo/bar/_other.scss' => 'a {b: c}'
                      })

            expect(described_class.compile(dir.path('input.scss'), load_paths: [dir.path('foo/bar')]).css)
              .to eq("a {\n  b: c;\n}")
          end
        end

        it "doesn't take precedence over loads relative to the entrypoint" do
          sandbox do |dir|
            dir.write({
                        'url/input.scss' => '@use "other";',
                        'url/_other.scss' => 'a {b: url}',
                        'load-path/_other.scss' => 'a {b: load path}'
                      })

            expect(described_class.compile(dir.path('url/input.scss'), load_paths: [dir.path('load-path')]).css)
              .to eq("a {\n  b: url;\n}")
          end
        end
      end
    end

    describe 'error' do
      it 'requires plain CSS for a .css file' do
        sandbox do |dir|
          dir.write({ 'input.css' => '$a: b; c {d: $a}' })
          expect { described_class.compile(dir.path('input.css')) }
            .to raise_error do |error|
              expect(error).to be_a(Sass::CompileError)
              expect(error.span.start.line).to eq(0)
              expect(error.span.url).to eq(dir.url('input.css'))
            end
        end
      end

      describe "includes the path's URL" do
        it 'in syntax errors' do
          sandbox do |dir|
            dir.write({ 'input.scss' => 'a {b:' })
            expect { described_class.compile(dir.path('input.scss')) }
              .to raise_error do |error|
                expect(error).to be_a(Sass::CompileError)
                expect(error.span.start.line).to eq(0)
                expect(error.span.url).to eq(dir.url('input.scss'))
              end
          end
        end

        it 'in runtime errors' do
          sandbox do |dir|
            dir.write({ 'input.scss' => '@error "oh no"' })
            expect { described_class.compile(dir.path('input.scss')) }
              .to raise_error do |error|
                expect(error).to be_a(Sass::CompileError)
                expect(error.span.start.line).to eq(0)
                expect(error.span.url).to eq(dir.url('input.scss'))
              end
          end
        end
      end
    end
  end
end
