# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/compiler.node.test.ts
# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/compiler.test.ts
RSpec.describe Sass::Compiler do
  subject!(:compiler) do
    described_class.new
  end

  after do
    compiler.close
  end

  let(:functions) do
    {
      'foo($args)' => ->(args) { args[0] }
    }
  end

  let(:importers) do
    [
      {
        canonicalize: ->(url, _) { "u:#{url}" },
        load: lambda do |url|
          {
            contents: ".import {value: #{url.split(':')[1]}} @debug \"imported\";",
            syntax: :scss
          }
        end
      }
    ]
  end

  let(:logger) do
    {
      debug: instance_double(Proc, call: nil)
    }
  end

  describe 'compile_string' do
    it 'performs complete compilations' do
      result = compiler.compile_string('@import "bar"; .fn {value: foo(baz)}', importers:, functions:, logger:)
      expect(result.css).to eq(".import {\n  value: bar;\n}\n\n.fn {\n  value: baz;\n}")
      expect(logger[:debug]).to have_received(:call).once
    end

    it 'performs compilations in callbacks' do
      nested_importer = {
        canonicalize: ->(*) { 'foo:bar' },
        load: lambda do |*|
          {
            contents: compiler.compile_string('x {y: z}').css,
            syntax: :scss
          }
        end
      }

      result = compiler.compile_string('@import "nested"; a {b: c}', importers: [nested_importer])
      expect(result.css).to eq("x {\n  y: z;\n}\n\na {\n  b: c;\n}")
    end

    it 'throws after being disposed' do
      compiler.close
      expect { compiler.compile_string('$a: b; c {d: $a}') }.to raise_error(IOError, 'closed compiler')
    end

    it 'succeeds after a compilation failure' do
      expect { compiler.compile_string('a') }.to raise_sass_compile_error.with_message('expected "{"')
      result = compiler.compile_string('x {y: z}')
      expect(result.css).to eq("x {\n  y: z;\n}")
    end

    it 'handles multiple concurrent compilations' do
      results = Array.new(100) do |i|
        Thread.new do
          compiler.compile_string("@import \"#{i}\"; .fn {value: foo(#{i})}", importers:, functions:, logger:)
        end
      end.map(&:value)

      results.each_with_index do |result, i|
        expect(result.css).to eq(".import {\n  value: #{i};\n}\n\n.fn {\n  value: #{i};\n}")
      end
    end
  end

  describe 'compile' do
    it 'performs complete compilations' do
      sandbox do |dir|
        dir.write({ 'input.scss' => '@import "bar"; .fn {value: foo(bar)}' })
        result = compiler.compile(dir.path('input.scss'), importers:, functions:, logger:)
        expect(result.css).to eq(".import {\n  value: bar;\n}\n\n.fn {\n  value: bar;\n}")
        expect(logger[:debug]).to have_received(:call).once
      end
    end

    it 'performs compilations in callbacks' do
      sandbox do |dir|
        dir.write({ 'input-nested.scss' => 'x {y: z}' })
        nested_importer = {
          canonicalize: ->(*) { 'foo:bar' },
          load: lambda do |*|
            {
              contents: compiler.compile(dir.path('input-nested.scss')).css,
              syntax: :scss
            }
          end
        }

        dir.write({ 'input.scss' => '@import "nested"; a {b: c}' })
        result = compiler.compile(dir.path('input.scss'), importers: [nested_importer])
        expect(result.css).to eq("x {\n  y: z;\n}\n\na {\n  b: c;\n}")
      end
    end

    it 'throws after being disposed' do
      sandbox do |dir|
        dir.write({ 'input.scss' => '$a: b; c {d: $a}' })
        compiler.close
        expect { compiler.compile(dir.path('input.scss')) }.to raise_error(IOError, 'closed compiler')
      end
    end

    it 'handles multiple concurrent compilations' do
      sandbox do |dir|
        results = Array.new(100) do |i|
          Thread.new do
            filename = "input-#{i}.scss"
            dir.write({ filename => "@import \"#{i}\"; .fn {value: foo(#{i})}" })
            compiler.compile(dir.path(filename), importers:, functions:, logger:)
          end
        end.map(&:value)

        results.each_with_index do |result, i|
          expect(result.css).to eq(".import {\n  value: #{i};\n}\n\n.fn {\n  value: #{i};\n}")
        end
      end
    end
  end
end
