# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sass::GemPackageImporter do
  around do |example|
    require 'bundler/inline'

    sandbox do |dir|
      bytes = if Gem.win_platform?
                [*32..127] - '<>:"/\|?*'.unpack('C*')
              else
                (1..127)
              end
      parent_dir = "#{bytes.map(&:chr).join}スタイル"
      dir.write({
                  "#{parent_dir}/_test.scss" => '/* test */',
                  "#{parent_dir}/_index.scss" => '@use "test";',
                  "#{parent_dir}/test.gemspec" => <<~GEMSPEC
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
        gem 'test', path: dir.path(parent_dir), require: false
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
