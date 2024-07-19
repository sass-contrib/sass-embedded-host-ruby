# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/importer.node.test.ts
# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/importer.test.ts
RSpec.describe Sass do
  it 'uses an importer to resolve a @use' do
    result = described_class.compile_string(
      '@use "orange";',
      importers: [{
        canonicalize: ->(url, _context) { "u:#{url}" },
        load: lambda { |url|
          color = url.split(':')[1]
          {
            contents: ".#{color} {color: #{color}}",
            syntax: 'scss'
          }
        }
      }]
    )

    expect(result.css).to eq(".orange {\n  color: orange;\n}")
  end

  it 'passes the canonicalized URL to the importer' do
    result = described_class.compile_string(
      '@use "orange";',
      importers: [{
        canonicalize: ->(*) { 'u:blue' },
        load: lambda { |url|
          color = url.split(':')[1]
          {
            contents: ".#{color} {color: #{color}}",
            syntax: 'scss'
          }
        }
      }]
    )

    expect(result.css).to eq(".blue {\n  color: blue;\n}")
  end

  it 'only invokes the importer once for a given canonicalization' do
    result = described_class.compile_string(
      '
      @import "orange";
      @import "orange";
      ',
      importers: [{
        canonicalize: ->(*) { 'u:blue' },
        load: lambda { |url|
          color = url.split(':')[1]
          {
            contents: ".#{color} {color: #{color}}",
            syntax: 'scss'
          }
        }
      }],
      silence_deprecations: ['import']
    )

    expect(result.css).to eq(".blue {\n  color: blue;\n}\n\n.blue {\n  color: blue;\n}")
  end

  describe 'the imported URL' do
    # Regression test for sass/dart-sass#1137.

    it "isn't changed if it's root-relative" do
      result = described_class.compile_string(
        '@use "/orange";',
        importers: [{
          canonicalize: lambda { |url, _context|
            expect(url).to eq('/orange')
            "u:#{url}"
          },
          load: lambda { |*|
            {
              contents: 'a {b: c}',
              syntax: 'scss'
            }
          }
        }]
      )

      expect(result.css).to eq("a {\n  b: c;\n}")
    end

    it "is converted to a file: URL if it's an absolute Windows path" do
      result = described_class.compile_string(
        '@import "C:/orange";',
        importers: [{
          canonicalize: lambda { |url, _context|
            expect(url).to eq('file:///C:/orange')
            "u:#{url}"
          },
          load: lambda { |*|
            {
              contents: 'a {b: c}',
              syntax: 'scss'
            }
          }
        }],
        silence_deprecations: ['import']
      )

      expect(result.css).to eq("a {\n  b: c;\n}")
    end
  end

  describe 'the containing URL' do
    it 'is nil for a potentially canonical scheme' do
      result = described_class.compile_string(
        '@use "u:orange"',
        importers: [{
          canonicalize: lambda { |url, context|
            expect(context.containing_url).to be_nil
            url
          },
          load: lambda { |*|
            {
              contents: '@a',
              syntax: 'scss'
            }
          }
        }]
      )

      expect(result.css).to eq('@a;')
    end

    describe 'for a non-canonical scheme' do
      describe 'in a list' do
        it 'is set to the original URL' do
          result = described_class.compile_string(
            '@use "u:orange"',
            importers: [{
              canonicalize: lambda { |url, context|
                expect(context.containing_url).to eq('x:original.scss')
                url.gsub(/^u:/, 'x:')
              },
              load: lambda { |*|
                {
                  contents: '@a',
                  syntax: 'scss'
                }
              },
              non_canonical_scheme: ['u']
            }],
            url: 'x:original.scss'
          )

          expect(result.css).to eq('@a;')
        end

        it 'is nil if the original URL is nil' do
          result = described_class.compile_string(
            '@use "u:orange"',
            importers: [{
              canonicalize: lambda { |url, context|
                expect(context.containing_url).to be_nil
                url.gsub(/^u:/, 'x:')
              },
              load: lambda { |*|
                {
                  contents: '@a',
                  syntax: 'scss'
                }
              },
              non_canonical_scheme: ['u']
            }]
          )

          expect(result.css).to eq('@a;')
        end
      end

      describe 'as a string' do
        it 'is set to the original URL' do
          result = described_class.compile_string(
            '@use "u:orange"',
            importers: [{
              canonicalize: lambda { |url, context|
                expect(context.containing_url).to eq('x:original.scss')
                url.gsub(/^u:/, 'x:')
              },
              load: lambda { |*|
                {
                  contents: '@a',
                  syntax: 'scss'
                }
              },
              non_canonical_scheme: 'u'
            }],
            url: 'x:original.scss'
          )

          expect(result.css).to eq('@a;')
        end

        it 'is nil if the original URL is nil' do
          result = described_class.compile_string(
            '@use "u:orange"',
            importers: [{
              canonicalize: lambda { |url, context|
                expect(context.containing_url).to be_nil
                url.gsub(/^u:/, 'x:')
              },
              load: lambda { |*|
                {
                  contents: '@a',
                  syntax: 'scss'
                }
              },
              non_canonical_scheme: 'u'
            }]
          )

          expect(result.css).to eq('@a;')
        end
      end
    end

    describe 'for a schemeless load' do
      it 'is set to the original URL' do
        result = described_class.compile_string(
          '@use "orange"',
          importers: [{
            canonicalize: lambda { |url, context|
              expect(context.containing_url).to eq('x:original.scss')
              "u:#{url}"
            },
            load: lambda { |*|
              {
                contents: '@a',
                syntax: 'scss'
              }
            }
          }],
          url: 'x:original.scss'
        )

        expect(result.css).to eq('@a;')
      end

      it 'is nil if the original URL is nil' do
        result = described_class.compile_string(
          '@use "orange"',
          importers: [{
            canonicalize: lambda { |url, context|
              expect(context.containing_url).to be_nil
              "u:#{url}"
            },
            load: lambda { |*|
              {
                contents: '@a',
                syntax: 'scss'
              }
            }
          }]
        )

        expect(result.css).to eq('@a;')
      end
    end
  end

  describe 'throws an error if the importer returns a canonical URL with a non-canonical scheme' do
    it 'set as a list' do
      expect do
        described_class.compile_string(
          '@use "orange"',
          importers: [{
            canonicalize: lambda { |url, _context|
              "u:#{url}"
            },
            load: lambda { |*|
              {
                contents: '@a',
                syntax: 'scss'
              }
            },
            non_canonical_scheme: ['u']
          }]
        )
      end.to raise_sass_compile_error.with_line(0)
    end

    it 'set as a string' do
      expect do
        described_class.compile_string(
          '@use "orange"',
          importers: [{
            canonicalize: lambda { |url, _context|
              "u:#{url}"
            },
            load: lambda { |*|
              {
                contents: '@a',
                syntax: 'scss'
              }
            },
            non_canonical_scheme: 'u'
          }]
        )
      end.to raise_sass_compile_error.with_line(0)
    end
  end

  describe 'throws an error for an invalid scheme:' do
    it 'empty' do
      expect do
        described_class.compile_string(
          'a {b: c}',
          importers: [{
            canonicalize: lambda { |*|
            },
            load: lambda { |*|
              {
                contents: '@a',
                syntax: 'scss'
              }
            },
            non_canonical_scheme: ''
          }]
        )
      end.to raise_sass_compile_error
    end

    it 'uppercase' do
      expect do
        described_class.compile_string(
          'a {b: c}',
          importers: [{
            canonicalize: lambda { |*|
            },
            load: lambda { |*|
              {
                contents: '@a',
                syntax: 'scss'
              }
            },
            non_canonical_scheme: 'U'
          }]
        )
      end.to raise_sass_compile_error
    end

    it 'colon' do
      expect do
        described_class.compile_string(
          'a {b: c}',
          importers: [{
            canonicalize: lambda { |*|
            },
            load: lambda { |*|
              {
                contents: '@a',
                syntax: 'scss'
              }
            },
            non_canonical_scheme: 'u:'
          }]
        )
      end.to raise_sass_compile_error
    end
  end

  it "uses an importer's source map URL" do
    result = described_class.compile_string(
      '@use "orange";',
      importers: [{
        canonicalize: lambda { |url, _context|
          "u:#{url}"
        },
        load: lambda { |url|
          color = url.split(':')[1]
          {
            contents: ".#{color} {color: #{color}}",
            syntax: 'scss',
            source_map_url: 'u:blue'
          }
        }
      }],
      source_map: true
    )

    expect(JSON.parse(result.source_map)['sources']).to include('u:blue')
  end

  it 'wraps an error in canonicalize()' do
    expect do
      described_class.compile_string(
        '@use "orange";',
        importers: [{
          canonicalize: lambda { |*|
            raise 'this import is bad actually'
          },
          load: lambda { |*|
            RSpec::Expectations.fail_with 'load() should not be called'
          }
        }]
      )
    end.to raise_sass_compile_error.with_line(0)
  end

  it 'wraps an error in load()' do
    expect do
      described_class.compile_string(
        '@use "orange";',
        importers: [{
          canonicalize: lambda { |url, _context|
            "u:#{url}"
          },
          load: lambda { |*|
            raise 'this import is bad actually'
          }
        }]
      )
    end.to raise_sass_compile_error.with_line(0)
  end

  it 'avoids importer when canonicalize() returns nil' do
    sandbox do |dir|
      dir.write({ 'dir/_other.scss' => 'a {from: dir}' })

      result = described_class.compile_string(
        '@use "other";',
        importers: [{
          canonicalize: ->(*) {},
          load: lambda { |*|
            raise 'this import is bad actually'
          }
        }],
        load_paths: [dir.path('dir')]
      )
      expect(result.css).to eq("a {\n  from: dir;\n}")
    end
  end

  it 'fails to import when load() returns nil' do
    sandbox do |dir|
      dir.write({ 'dir/_other.scss' => 'a {from: dir}' })

      expect do
        described_class.compile_string(
          '@use "other";',
          importers: [{
            canonicalize: lambda { |url, _context|
              "u:#{url}"
            },
            load: ->(*) {}
          }],
          load_paths: [dir.path('dir')]
        )
      end.to raise_sass_compile_error.with_line(0)
    end
  end

  it 'prefers a relative file load to an importer' do
    sandbox do |dir|
      dir.write({
                  'input.scss' => '@use "other"',
                  '_other.scss' => 'a {from: relative}'
                })

      result = described_class.compile(
        dir.path('input.scss'),
        importers: [{
          canonicalize: lambda { |*|
            raise 'canonicalize() should not be called'
          },
          load: lambda { |*|
            raise 'load() should not be called'
          }
        }]
      )
      expect(result.css).to eq("a {\n  from: relative;\n}")
    end
  end

  it 'prefers an importer to a load path' do
    sandbox do |dir|
      dir.write({
                  'input.scss' => '@use "other"',
                  'dir/_other.scss' => 'a {from: load-path}'
                })

      result = described_class.compile(
        dir.path('input.scss'),
        importers: [{
          canonicalize: lambda { |url, _context|
            "u:#{url}"
          },
          load: lambda { |*|
            {
              contents: 'a {from: importer}', syntax: 'scss'
            }
          }
        }],
        load_paths: [dir.path('dir')]
      )
      expect(result.css).to eq("a {\n  from: importer;\n}")
    end
  end

  describe 'with syntax' do
    it 'scss, parses it as SCSS' do
      result = described_class.compile_string(
        '@use "other";',
        importers: [{
          canonicalize: ->(*) { 'u:other' },
          load: lambda { |*|
            { contents: '$a: value; b {c: $a}', syntax: 'scss' }
          }
        }]
      )

      expect(result.css).to eq("b {\n  c: value;\n}")
    end

    it 'indented, parses it as the indented syntax' do
      result = described_class.compile_string(
        '@use "other";',
        importers: [{
          canonicalize: ->(*) { 'u:other' },
          load: lambda { |*|
            { contents: "$a: value\nb\n  c: $a", syntax: 'indented' }
          }
        }]
      )

      expect(result.css).to eq("b {\n  c: value;\n}")
    end

    it 'css, allows plain CSS' do
      result = described_class.compile_string(
        '@use "other";',
        importers: [{
          canonicalize: ->(*) { 'u:other' },
          load: lambda { |*|
            { contents: 'a {b: c}', syntax: 'css' }
          }
        }]
      )

      expect(result.css).to eq("a {\n  b: c;\n}")
    end

    it 'css, rejects SCSS' do
      expect do
        described_class.compile_string(
          '@use "other";',
          importers: [{
            canonicalize: ->(*) { 'u:other' },
            load: lambda { |*|
              { contents: "$a: value\nb\n  c: $a", syntax: 'css' }
            }
          }]
        )
      end.to raise_sass_compile_error.with_line(0)
    end
  end

  describe "compile_string()'s importer option" do
    it 'loads relative imports from the entrypoint' do
      result = described_class.compile_string(
        '@use "orange";',
        importer: {
          canonicalize: lambda { |url, _context|
            expect(url).to eq('u:orange')
            url
          },
          load: lambda { |url|
            color = url.split(':')[1]
            {
              contents: ".#{color} {color: #{color}}",
              syntax: 'scss'
            }
          }
        },
        url: 'u:entrypoint'
      )

      expect(result.css).to eq(".orange {\n  color: orange;\n}")
    end

    it 'takes precedence over the importer list for relative URLs' do
      result = described_class.compile_string(
        '@use "other";',
        importer: {
          canonicalize: lambda { |url, _context|
            url
          },
          load: lambda { |_url|
            {
              contents: 'a {from: relative}',
              syntax: 'scss'
            }
          }
        },
        importers: [{
          canonicalize: lambda { |*|
            raise 'canonicalize() should not be called'
          },
          load: lambda { |*|
            raise 'load() should not be called'
          }
        }],
        url: 'o:style.scss'
      )

      expect(result.css).to eq("a {\n  from: relative;\n}")
    end

    it "doesn't load absolute imports" do
      result = described_class.compile_string(
        '@use "u:orange";',
        importer: {
          canonicalize: lambda { |*|
            raise 'canonicalize() should not be called'
          },
          load: lambda { |*|
            raise 'load() should not be called'
          }
        },
        importers: [{
          canonicalize: lambda { |url, _context|
            expect(url).to eq('u:orange')
            url
          },
          load: lambda { |url|
            color = url.split(':')[1]
            {
              contents: ".#{color} {color: #{color}}",
              syntax: 'scss'
            }
          }
        }],
        url: 'x:entrypoint'
      )

      expect(result.css).to eq(".orange {\n  color: orange;\n}")
    end

    it "doesn't load from other importers" do
      result = described_class.compile_string(
        '@use "u:midstream";',
        importer: {
          canonicalize: lambda { |*|
            raise 'canonicalize() should not be called'
          },
          load: lambda { |*|
            raise 'load() should not be called'
          }
        },
        importers: [{
          canonicalize: lambda { |url, _context|
            url
          },
          load: lambda { |url|
            pathname = url.split(':')[1]
            if pathname == 'midstream'
              {
                contents: "@use 'orange';",
                syntax: 'scss'
              }
            else
              color = pathname
              {
                contents: ".#{color} {color: #{color}}",
                syntax: 'scss'
              }
            end
          }
        }],
        url: 'x:entrypoint'
      )

      expect(result.css).to eq(".orange {\n  color: orange;\n}")
    end

    it 'importer order is preserved for absolute imports' do
      # The second importer should only be invoked once, because when the
      # "first:other" import is resolved it should be passed to the first
      # importer first despite being in the second importer's file.
      second_called = false
      result = described_class.compile_string(
        '@use "second:other";',
        importers: [{
          canonicalize: lambda { |url, _context|
            url if url.start_with?('first:')
          },
          load: lambda { |*|
            {
              contents: 'a {from: first}',
              syntax: 'scss'
            }
          }
        }, {
          canonicalize: lambda { |url, _context|
            raise 'Second importer should only be called once.' if second_called

            second_called = true
            url if url.start_with?('second:')
          },
          load: lambda { |*|
            {
              contents: '@use "first:other";',
              syntax: 'scss'
            }
          }
        }]
      )

      expect(result.css).to eq("a {\n  from: first;\n}")
    end
  end

  describe 'from_import is' do
    def expect_from_import(canonicalize, expected)
      allow(canonicalize).to receive(:call) { |url, context|
        expect(context.from_import).to be(expected)
        "u:#{url}"
      }
      {
        canonicalize: ->(*args) { canonicalize.call(*args) },
        load: ->(*) { { contents: '', syntax: 'scss' } }
      }
    end

    it 'true from an @import' do
      canonicalize = double

      described_class.compile_string(
        '@import "foo"',
        importers: [expect_from_import(canonicalize, true)],
        silence_deprecations: ['import']
      )

      expect(canonicalize).to have_received(:call)
    end

    it 'false from an @use' do
      canonicalize = double

      described_class.compile_string(
        '@use "foo"',
        importers: [expect_from_import(canonicalize, false)]
      )

      expect(canonicalize).to have_received(:call)
    end

    it 'false from an @forward' do
      canonicalize = double

      described_class.compile_string(
        '@forward "foo"',
        importers: [expect_from_import(canonicalize, false)]
      )

      expect(canonicalize).to have_received(:call)
    end

    it 'false from meta.load-css' do
      canonicalize = double

      described_class.compile_string(
        '@use "sass:meta"; @include meta.load-css("")',
        importers: [expect_from_import(canonicalize, false)]
      )

      expect(canonicalize).to have_received(:call)
    end
  end

  describe 'FileImporter' do
    it 'loads a fully canonicalized URL' do
      sandbox do |dir|
        dir.write({ '_other.scss' => 'a {b: c}' })

        result = described_class.compile_string(
          '@use "other";',
          importers: [{
            find_file_url: ->(*) { dir.url('_other.scss') }
          }]
        )
        expect(result.css).to eq("a {\n  b: c;\n}")
      end
    end

    it 'resolves a non-canonicalized URL' do
      sandbox do |dir|
        dir.write({ 'other/_index.scss' => 'a {b: c}' })

        result = described_class.compile_string(
          '@use "other";',
          importers: [{
            find_file_url: ->(*) { dir.url('other') }
          }]
        )
        expect(result.css).to eq("a {\n  b: c;\n}")
      end
    end

    it 'avoids importer when it returns nil' do
      sandbox do |dir|
        dir.write({ '_other.scss' => 'a {from: dir}' })

        result = described_class.compile_string(
          '@use "other";',
          importers: [{
            find_file_url: ->(*) {}
          }],
          load_paths: [dir.root]
        )
        expect(result.css).to eq("a {\n  from: dir;\n}")
      end
    end

    it 'avoids importer when it returns an unresolvable URL' do
      sandbox do |dir|
        dir.write({ '_other.scss' => 'a {from: dir}' })

        result = described_class.compile_string(
          '@use "other";',
          importers: [{
            find_file_url: ->(*) { dir.url('nonexistent/other') }
          }],
          load_paths: [dir.root]
        )
        expect(result.css).to eq("a {\n  from: dir;\n}")
      end
    end

    it 'passes an absolute non-file: URL to the importer' do
      sandbox do |dir|
        dir.write({ 'dir/_other.scss' => 'a {b: c}' })

        result = described_class.compile_string(
          '@use "u:other";',
          importers: [{
            find_file_url: lambda { |url, _context|
              expect(url).to eq('u:other')
              dir.url('dir/other')
            }
          }],
          load_paths: [dir.root]
        )
        expect(result.css).to eq("a {\n  b: c;\n}")
      end
    end

    it "doesn't pass an absolute file: URL to the importer" do
      sandbox do |dir|
        dir.write({ '_other.scss' => 'a {b: c}' })

        result = described_class.compile_string(
          "@use \"#{dir.url('other')}\";",
          importers: [{
            find_file_url: lambda { |*|
              raise 'find_file_url() should not be called'
            }
          }]
        )
        expect(result.css).to eq("a {\n  b: c;\n}")
      end
    end

    it "doesn't pass relative loads to the importer" do
      sandbox do |dir|
        dir.write({ '_midstream.scss' => '@use "upstream"' })
        dir.write({ '_upstream.scss' => 'a {b: c}' })

        count = 0
        result = described_class.compile_string(
          '@use "midstream";',
          importers: [{
            find_file_url: lambda { |*|
              raise 'find_file_url() should only be called once' if count > 0

              count += 1
              dir.url('upstream')
            }
          }]
        )
        expect(result.css).to eq("a {\n  b: c;\n}")
      end
    end

    it 'wraps an error' do
      expect do
        described_class.compile_string(
          '@use "other";',
          importers: [
            {
              find_file_url: lambda { |*|
                raise 'this import is bad actually'
              }
            }
          ]
        )
      end.to raise_sass_compile_error.with_line(0)
    end

    it 'rejects a non-file URL' do
      expect do
        described_class.compile_string(
          '@use "other";',
          importers: [{ find_file_url: ->(*) { 'u:other.scss' } }]
        )
      end.to raise_sass_compile_error.with_line(0)
    end

    describe 'when the resolved file has extension' do
      it '.scss, parses it as SCSS' do
        sandbox do |dir|
          dir.write({ '_other.scss' => '$a: value; b {c: $a}' })

          result = described_class.compile_string(
            '@use "other";',
            importers: [{ find_file_url: ->(*) { dir.url('other') } }]
          )
          expect(result.css).to eq("b {\n  c: value;\n}")
        end
      end

      it '.sass, parses it as the indented syntax' do
        sandbox do |dir|
          dir.write({ '_other.sass' => "$a: value\nb\n  c: $a" })

          result = described_class.compile_string(
            '@use "other";',
            importers: [{ find_file_url: ->(*) { dir.url('other') } }]
          )
          expect(result.css).to eq("b {\n  c: value;\n}")
        end
      end

      it '.css, allows plain CSS' do
        sandbox do |dir|
          dir.write({ '_other.css' => 'a {b: c}' })

          result = described_class.compile_string(
            '@use "other";',
            importers: [{ find_file_url: ->(*) { dir.url('other') } }]
          )
          expect(result.css).to eq("a {\n  b: c;\n}")
        end
      end

      it '.css, rejects SCSS' do
        sandbox do |dir|
          dir.write({ '_other.css' => '$a: value; b {c: $a}' })

          expect do
            described_class.compile_string(
              '@use "other";',
              importers: [{ find_file_url: ->(*) { dir.url('other') } }]
            )
          end.to raise_sass_compile_error.with_line(0).with_url(dir.url('_other.css'))
        end
      end
    end

    describe 'from_import is' do
      it 'true from an @import' do
        sandbox do |dir|
          dir.write({ '_other.scss' => 'a {b: c}' })

          described_class.compile_string(
            '@import "other";',
            importers: [{
              find_file_url: lambda { |_url, context|
                expect(context.from_import).to be(true)
                dir.url('other')
              }
            }],
            silence_deprecations: ['import']
          )
        end
      end

      it 'false from a @use' do
        sandbox do |dir|
          dir.write({ '_other.scss' => 'a {b: c}' })

          described_class.compile_string(
            '@use "other";',
            importers: [{
              find_file_url: lambda { |_url, context|
                expect(context.from_import).to be(false)
                dir.url('other')
              }
            }]
          )
        end
      end
    end
  end

  describe 'containing_url is' do
    it 'set for a relative URL' do
      sandbox do |dir|
        dir.write({ '_other.scss' => 'a {b: c}' })
        result = described_class.compile_string(
          '@use "other";',
          importers: [{
            find_file_url: lambda { |_url, context|
              expect(context.containing_url).to eq('x:original.scss')
              dir.url('other')
            }
          }],
          url: 'x:original.scss'
        )
        expect(result.css).to eq("a {\n  b: c;\n}")
      end
    end

    it 'set for an absolute URL' do
      sandbox do |dir|
        dir.write({ '_other.scss' => 'a {b: c}' })
        result = described_class.compile_string(
          '@use "u:other";',
          importers: [{
            find_file_url: lambda { |_url, context|
              expect(context.containing_url).to eq('x:original.scss')
              dir.url('other')
            }
          }],
          url: 'x:original.scss'
        )
        expect(result.css).to eq("a {\n  b: c;\n}")
      end
    end

    it 'unset when the URL is unavailable' do
      sandbox do |dir|
        dir.write({ '_other.scss' => 'a {b: c}' })
        result = described_class.compile_string(
          '@use "u:other";',
          importers: [{
            find_file_url: lambda { |_url, context|
              expect(context.containing_url).to be_nil
              dir.url('other')
            }
          }]
        )
        expect(result.css).to eq("a {\n  b: c;\n}")
      end
    end
  end

  it "throws an error for an importer that's ambiguous between FileImporter and Importer" do
    sandbox do |dir|
      dir.write({ '_other.scss' => 'a {b: c}' })

      expect do
        described_class.compile_string(
          '@use "other";',
          importers: [{
            find_file_url: lambda { |*|
              dir.url('other')
            },
            canonicalize: lambda { |*|
              dir.url('other')
            },
            load: lambda { |*|
              { contents: 'a {b: c}', syntax: 'scss' }
            }
          }]
        )
      end.to raise_error(ArgumentError)
    end
  end

  describe 'when importer does not return string contents' do
    it 'throws an error in sync mode' do
      expect do
        described_class.compile_string(
          '@use "other";',
          importers: [{
            canonicalize: ->(url, _context) { "u:#{url}" },
            load: lambda { |*|
              {
                contents: :'not a string',
                syntax: 'scss'
              }
            }
          }]
        )
      end.to raise_sass_compile_error.with_line(0).with_message('undefined method')
    end
  end

  it 'throws an ArgumentError when the result source_map_url is missing a scheme' do
    expect do
      described_class.compile_string(
        '@use "other";',
        importers: [{
          canonicalize: ->(url, _context) { "u:#{url}" },
          load: lambda { |*|
            {
              contents: '',
              syntax: 'scss',
              source_map_url: {}
            }
          }
        }]
      )
    end.to raise_sass_compile_error.with_line(0).with_message(
      'The importer must return an absolute URL'
    )
  end
end
