# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sass::GemPackageImporter do
  around do |example|
    require 'bundler/inline'

    sandbox do |dir|
      dir.write({
                  '_test.scss' => '/* test */',
                  '_index.scss' => '@use "test";',
                  'test.gemspec' => <<~GEMSPEC
                    Gem::Specification.new do |spec|
                      spec.name = 'test'
                      spec.summary = 'test'
                      spec.authors = ['test']
                      spec.version = '0.0.1'
                      spec.files = Dir['**/*']
                    end
                  GEMSPEC
                })

      gemfile do
        gem 'test', path: dir.path, require: false
      end

      example.call
    end
  end

  describe 'resolves pkg: url' do
    it 'without subpath' do
      expect(Sass.compile_string('@use "pkg:test";',
                                 importers: [described_class.new],
                                 logger: Sass::Logger.silent).css)
        .to eq('/* test */')
    end

    it 'with subpath' do
      expect(Sass.compile_string('@use "pkg:test/test";',
                                 importers: [described_class.new],
                                 logger: Sass::Logger.silent).css)
        .to eq('/* test */')
    end

    it 'with uppercase scheme' do
      expect(Sass.compile_string('@use "PKG:test";',
                                 importers: [described_class.new],
                                 logger: Sass::Logger.silent).css)
        .to eq('/* test */')
    end

    it 'with precent-encoding' do
      expect(Sass.compile_string('@use "pkg:%74%65%73%74";',
                                 importers: [described_class.new],
                                 logger: Sass::Logger.silent).css)
        .to eq('/* test */')
    end
  end
end
