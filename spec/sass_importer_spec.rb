# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sass do
  it 'uses an importer to resolve an @import' do
    result = described_class.compile_string('@import "orange";',
                                            importers: [
                                              {
                                                canonicalize: ->(url, **_kwargs) { "u:#{url}" },
                                                load: lambda { |url|
                                                  color = url.split(':')[1]
                                                  return {
                                                    contents: ".#{color} {color: #{color}}",
                                                    syntax: 'scss'
                                                  }
                                                }
                                              }
                                            ])

    expect(result.css).to eq(".orange {\n  color: orange;\n}")
  end

  it 'passes the canonicalized URL to the importer' do
    result = described_class.compile_string('@import "orange";',
                                            importers: [
                                              {
                                                canonicalize: ->(_url, **_kwargs) { 'u:blue' },
                                                load: lambda { |url|
                                                  color = url.split(':')[1]
                                                  return {
                                                    contents: ".#{color} {color: #{color}}",
                                                    syntax: 'scss'
                                                  }
                                                }
                                              }
                                            ])

    expect(result.css).to eq(".blue {\n  color: blue;\n}")
  end

  it 'only invokes the importer once for a given canonicalization' do
    result = described_class.compile_string('
                                            @import "orange";
                                            @import "orange";
                                            ',
                                            importers: [
                                              {
                                                canonicalize: ->(_url, **_kwargs) { 'u:blue' },
                                                load: lambda { |url|
                                                  color = url.split(':')[1]
                                                  return {
                                                    contents: ".#{color} {color: #{color}}",
                                                    syntax: 'scss'
                                                  }
                                                }
                                              }
                                            ])

    expect(result.css).to eq(".blue {\n  color: blue;\n}\n\n.blue {\n  color: blue;\n}")
  end

  describe 'the imported URL' do
    # Regression test for sass/dart-sass#1137.

    it "isn't changed if it's root-relative" do
      result = described_class.compile_string('@import "/orange";',
                                              importers: [
                                                {
                                                  canonicalize: lambda { |url, **_kwargs|
                                                    expect(url).to eq('/orange')
                                                    "u:#{url}"
                                                  },
                                                  load: lambda { |_url|
                                                    return {
                                                      contents: 'a {b: c}',
                                                      syntax: 'scss'
                                                    }
                                                  }
                                                }
                                              ])

      expect(result.css).to eq("a {\n  b: c;\n}")
    end

    it "is converted to a file: URL if it's an absolute Windows path" do
      result = described_class.compile_string('@import "C:/orange";',
                                              importers: [
                                                {
                                                  canonicalize: lambda { |url, **_kwargs|
                                                    expect(url).to eq('file:///C:/orange')
                                                    "u:#{url}"
                                                  },
                                                  load: lambda { |_url|
                                                    return {
                                                      contents: 'a {b: c}',
                                                      syntax: 'scss'
                                                    }
                                                  }
                                                }
                                              ])

      expect(result.css).to eq("a {\n  b: c;\n}")
    end
  end

  it "uses an importer's source map URL" do
    result = described_class.compile_string('@import "orange";',
                                            importers: [
                                              {
                                                canonicalize: lambda { |url, **_kwargs|
                                                  "u:#{url}"
                                                },
                                                load: lambda { |url|
                                                  color = url.split(':')[1]
                                                  return {
                                                    contents: ".#{color} {color: #{color}}",
                                                    syntax: 'scss',
                                                    source_map_url: 'u:blue'
                                                  }
                                                }
                                              }
                                            ],
                                            source_map: true)

    expect(JSON.parse(result.source_map)['sources']).to include('u:blue')
  end

  it 'wraps an error in canonicalize()' do
    expect do
      described_class.compile_string('@import "orange";',
                                     importers: [
                                       {
                                         canonicalize: lambda { |_url, **_kwargs|
                                           raise 'this import is bad actually'
                                         },
                                         load: lambda { |_url|
                                           RSpec::Expectations.fail_with 'load() should not be called'
                                         }
                                       }
                                     ])
    end.to raise_error do |error|
      expect(error).to be_a(Sass::CompileError)
      expect(error.span.start.line).to eq(0)
    end
  end

  it 'wraps an error in load()' do
    expect do
      described_class.compile_string('@import "orange";',
                                     importers: [
                                       {
                                         canonicalize: lambda { |url, **_kwargs|
                                           "u:#{url}"
                                         },
                                         load: lambda { |_url|
                                           raise 'this import is bad actually'
                                         }
                                       }
                                     ])
    end.to raise_error do |error|
      expect(error).to be_a(Sass::CompileError)
      expect(error.span.start.line).to eq(0)
    end
  end

  it 'avoids importer when canonicalize() returns nil' do
    sandbox do |dir|
      dir.write({ 'dir/_other.scss' => 'a {from: dir}' })

      result = described_class.compile_string('@import "other";',
                                              importers: [
                                                {
                                                  canonicalize: ->(_url, **_kwargs) {},
                                                  load: lambda { |_url|
                                                    raise 'this import is bad actually'
                                                  }
                                                }
                                              ],
                                              load_paths: [dir.path('dir')])
      expect(result.css).to eq("a {\n  from: dir;\n}")
    end
  end

  it 'fails to import when load() returns nil' do
    sandbox do |dir|
      dir.write({ 'dir/_other.scss' => 'a {from: dir}' })

      expect do
        described_class.compile_string('@import "other";',
                                       importers: [
                                         {
                                           canonicalize: lambda { |url, **_kwargs|
                                             "u:#{url}"
                                           },
                                           load: ->(_url) {}
                                         }
                                       ],
                                       load_paths: [dir.path('dir')])
      end.to raise_error do |error|
        expect(error).to be_a(Sass::CompileError)
        expect(error.span.start.line).to eq(0)
      end
    end
  end

  it 'prefers a relative file load to an importer' do
    sandbox do |dir|
      dir.write({
                  'input.scss' => '@import "other"',
                  '_other.scss' => 'a {from: relative}'
                })

      result = described_class.compile(dir.path('input.scss'),
                                       importers: [
                                         {
                                           canonicalize: lambda { |_url, **_kwargs|
                                             raise 'canonicalize() should not be called'
                                           },
                                           load: lambda { |_url|
                                             raise 'load() should not be called'
                                           }
                                         }
                                       ])
      expect(result.css).to eq("a {\n  from: relative;\n}")
    end
  end

  it 'prefers a relative importer load to an importer' do
    result = described_class.compile_string('@import "other";',
                                            importers: [
                                              {
                                                canonicalize: lambda { |_url, **_kwargs|
                                                  raise 'canonicalize() should not be called'
                                                },
                                                load: lambda { |_url|
                                                  raise 'load() should not be called'
                                                }
                                              }
                                            ],
                                            url: 'o:style.scss',
                                            importer: {
                                              canonicalize: ->(url, **_kwargs) { url },
                                              load: lambda { |_url|
                                                return {
                                                  contents: 'a {from: relative}',
                                                  syntax: 'scss'
                                                }
                                              }
                                            })
    expect(result.css).to eq("a {\n  from: relative;\n}")
  end

  it 'prefers an importer to a load path' do
    sandbox do |dir|
      dir.write({
                  'input.scss' => '@import "other"',
                  'dir/_other.scss' => 'a {from: load-path}'
                })

      result = described_class.compile(dir.path('input.scss'),
                                       importers: [
                                         {
                                           canonicalize: lambda { |url, **_kwargs|
                                             "u:#{url}"
                                           },
                                           load: lambda { |_url|
                                             return {
                                               contents: 'a {from: importer}', syntax: 'scss'
                                             }
                                           }
                                         }
                                       ],
                                       load_paths: [dir.path('dir')])
      expect(result.css).to eq("a {\n  from: importer;\n}")
    end
  end

  describe 'with syntax' do
    it 'scss, parses it as SCSS' do
      result = described_class.compile_string('@import "other";',
                                              importers: [
                                                {
                                                  canonicalize: ->(_url, **_kwargs) { 'u:other' },
                                                  load: lambda { |_url|
                                                          return { contents: '$a: value; b {c: $a}', syntax: 'scss' }
                                                        }
                                                }
                                              ])

      expect(result.css).to eq("b {\n  c: value;\n}")
    end

    it 'indented, parses it as the indented syntax' do
      result = described_class.compile_string('@import "other";',
                                              importers: [
                                                {
                                                  canonicalize: ->(_url, **_kwargs) { 'u:other' },
                                                  load: lambda { |_url|
                                                          return { contents: "$a: value\nb\n  c: $a",
                                                                   syntax: 'indented' }
                                                        }
                                                }
                                              ])

      expect(result.css).to eq("b {\n  c: value;\n}")
    end

    it 'css, allows plain CSS' do
      result = described_class.compile_string('@import "other";',
                                              importers: [
                                                {
                                                  canonicalize: ->(_url, **_kwargs) { 'u:other' },
                                                  load: lambda { |_url|
                                                          return { contents: 'a {b: c}',
                                                                   syntax: 'css' }
                                                        }
                                                }
                                              ])

      expect(result.css).to eq("a {\n  b: c;\n}")
    end

    it 'css, rejects SCSS' do
      expect do
        described_class.compile_string('@import "other";',
                                       importers: [
                                         {
                                           canonicalize: ->(_url, **_kwargs) { 'u:other' },
                                           load: lambda { |_url|
                                                   return { contents: "$a: value\nb\n  c: $a",
                                                            syntax: 'css' }
                                                 }
                                         }
                                       ])
      end.to raise_error do |error|
        expect(error).to be_a(Sass::CompileError)
        expect(error.span.start.line).to eq(0)
      end
    end
  end

  describe 'from_import is' do
    def expect_from_import(expected)
      {
        canonicalize: lambda { |url, from_import:|
          expect(from_import).to be(expected)
          "u:#{url}"
        },
        load: ->(_url) { return { contents: '', syntax: 'scss' } }
      }
    end

    it 'true from an @import' do
      described_class.compile_string('@import "foo"', importers: [expect_from_import(true)])
    end

    it 'false from an @use' do
      described_class.compile_string('@use "foo"', importers: [expect_from_import(false)])
    end

    it 'false from an @forward' do
      described_class.compile_string('@forward "foo"', importers: [expect_from_import(false)])
    end

    it 'false from meta.load-css' do
      described_class.compile_string('@use "sass:meta"; @include meta.load-css("")',
                                     importers: [expect_from_import(false)])
    end
  end

  describe 'FileImporter' do
    it 'loads a fully canonicalized URL' do
      sandbox do |dir|
        dir.write({ '_other.scss' => 'a {b: c}' })

        result = described_class.compile_string('@import "other";',
                                                importers: [{
                                                  find_file_url: ->(_url, **_kwargs) { dir.url('_other.scss') }
                                                }])
        expect(result.css).to eq("a {\n  b: c;\n}")
      end
    end

    it 'resolves a non-canonicalized URL' do
      sandbox do |dir|
        dir.write({ 'other/_index.scss' => 'a {b: c}' })

        result = described_class.compile_string('@import "other";',
                                                importers: [{
                                                  find_file_url: ->(_url, **_kwargs) { dir.url('other') }
                                                }])
        expect(result.css).to eq("a {\n  b: c;\n}")
      end
    end

    it 'avoids importer when it returns nil' do
      sandbox do |dir|
        dir.write({ '_other.scss' => 'a {from: dir}' })

        result = described_class.compile_string('@import "other";',
                                                importers: [{
                                                  find_file_url: ->(_url, **_kwargs) {}
                                                }],
                                                load_paths: [dir.root])
        expect(result.css).to eq("a {\n  from: dir;\n}")
      end
    end

    it 'avoids importer when it returns an unresolvable URL' do
      sandbox do |dir|
        dir.write({ '_other.scss' => 'a {from: dir}' })

        result = described_class.compile_string('@import "other";',
                                                importers: [{
                                                  find_file_url: lambda { |_url, **_kwargs|
                                                    dir.url('nonexistent/other')
                                                  }
                                                }],
                                                load_paths: [dir.root])
        expect(result.css).to eq("a {\n  from: dir;\n}")
      end
    end

    it 'passes an absolute non-file: URL to the importer' do
      sandbox do |dir|
        dir.write({ 'dir/_other.scss' => 'a {b: c}' })

        result = described_class.compile_string('@import "u:other";',
                                                importers: [{
                                                  find_file_url: lambda { |url, **_kwargs|
                                                    expect(url).to eq('u:other')
                                                    dir.url('dir/other')
                                                  }
                                                }],
                                                load_paths: [dir.root])
        expect(result.css).to eq("a {\n  b: c;\n}")
      end
    end

    it "doesn't pass an absolute file: URL to the importer" do
      sandbox do |dir|
        dir.write({ '_other.scss' => 'a {b: c}' })

        result = described_class.compile_string("@import \"#{dir.url('other')}\";",
                                                importers: [{
                                                  find_file_url: lambda { |_url, **_kwargs|
                                                    raise 'find_file_url() should not be called'
                                                  }
                                                }])
        expect(result.css).to eq("a {\n  b: c;\n}")
      end
    end

    it "doesn't pass relative loads to the importer" do
      sandbox do |dir|
        dir.write({ '_midstream.scss' => '@import "upstream"' })
        dir.write({ '_upstream.scss' => 'a {b: c}' })

        count = 0
        result = described_class.compile_string('@import "midstream";',
                                                importers: [{
                                                  find_file_url: lambda { |_url, **_kwargs|
                                                    raise 'find_file_url() should only be called once' if count > 0

                                                    count += 1
                                                    dir.url('upstream')
                                                  }
                                                }])
        expect(result.css).to eq("a {\n  b: c;\n}")
      end
    end

    it 'wraps an error' do
      expect do
        described_class.compile_string('@import "other";',
                                       importers: [
                                         {
                                           find_file_url: lambda { |_url, **_kwargs|
                                             raise 'this import is bad actually'
                                           }
                                         }
                                       ])
      end.to raise_error do |error|
        expect(error).to be_a(Sass::CompileError)
        expect(error.span.start.line).to eq(0)
      end
    end

    it 'rejects a non-file URL' do
      expect do
        described_class.compile_string('@import "other";',
                                       importers: [{ find_file_url: ->(_url, **_kwargs) { 'u:other.scss' } }])
      end.to raise_error do |error|
        expect(error).to be_a(Sass::CompileError)
        expect(error.span.start.line).to eq(0)
      end
    end

    describe 'when the resolved file has extension' do
      it '.scss, parses it as SCSS' do
        sandbox do |dir|
          dir.write({ '_other.scss' => '$a: value; b {c: $a}' })

          result = described_class.compile_string('@import "other";',
                                                  importers: [{ find_file_url: lambda { |_url, **_kwargs|
                                                                                 dir.url('other')
                                                                               } }])
          expect(result.css).to eq("b {\n  c: value;\n}")
        end
      end

      it '.sass, parses it as the indented syntax' do
        sandbox do |dir|
          dir.write({ '_other.sass' => "$a: value\nb\n  c: $a" })

          result = described_class.compile_string('@import "other";',
                                                  importers: [{ find_file_url: lambda { |_url, **_kwargs|
                                                                                 dir.url('other')
                                                                               } }])
          expect(result.css).to eq("b {\n  c: value;\n}")
        end
      end

      it '.css, allows plain CSS' do
        sandbox do |dir|
          dir.write({ '_other.css' => 'a {b: c}' })

          result = described_class.compile_string('@import "other";',
                                                  importers: [{ find_file_url: lambda { |_url, **_kwargs|
                                                                                 dir.url('other')
                                                                               } }])
          expect(result.css).to eq("a {\n  b: c;\n}")
        end
      end

      it '.css, rejects SCSS' do
        sandbox do |dir|
          dir.write({ '_other.css' => '$a: value; b {c: $a}' })

          expect do
            described_class.compile_string('@import "other";',
                                           importers: [{ find_file_url: lambda { |_url, **_kwargs|
                                                                          dir.url('other')
                                                                        } }])
          end.to raise_error do |error|
            expect(error).to be_a(Sass::CompileError)
            expect(error.span.start.line).to eq(0)
            expect(error.span.url).to eq(dir.url('_other.css'))
          end
        end
      end
    end

    describe 'from_import is' do
      it 'true from an @import' do
        sandbox do |dir|
          dir.write({ '_other.scss' => 'a {b: c}' })

          described_class.compile_string('@import "other";',
                                         importers: [{ find_file_url: lambda { |_url, from_import:|
                                                                        expect(from_import).to be(true)
                                                                        dir.url('other')
                                                                      } }])
        end
      end

      it 'false from a @use' do
        sandbox do |dir|
          dir.write({ '_other.scss' => 'a {b: c}' })

          described_class.compile_string('@use "other";',
                                         importers: [{ find_file_url: lambda { |_url, from_import:|
                                                                        expect(from_import).to be(false)
                                                                        dir.url('other')
                                                                      } }])
        end
      end
    end
  end

  it "throws an error for an importer that's ambiguous between FileImporter and Importer" do
    sandbox do |dir|
      dir.write({ '_other.scss' => 'a {b: c}' })

      expect do
        described_class.compile_string('@import "other";',
                                       importers: [{
                                         find_file_url: lambda { |_url, **_kwargs|
                                           dir.url('other')
                                         },
                                         canonicalize: lambda { |_url, **_kwargs|
                                           dir.url('other')
                                         },
                                         load: lambda { |_url|
                                           return { contents: 'a {b: c}', syntax: 'scss' }
                                         }
                                       }])
      end.to raise_error do |error|
        expect(error).not_to be_a(Sass::CompileError)
      end
    end
  end
end
