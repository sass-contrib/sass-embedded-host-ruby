# frozen_string_literal: true

require 'spec_helper'

describe Sass::Value::String do
  describe '.to_s' do
    describe 'serialize quoted string' do
      it 'without quote in text' do
        string = described_class.new('c')
        expected = Sass.compile_string('a { b: foo() }', functions: { 'foo()' => ->(_) { string } }).css
        actual = Sass.compile_string("a { b: #{string} }").css
        expect(actual).to eq(expected)

        expected = Sass.compile_string(expected).css
        expect(actual).to eq(expected)
      end

      it 'with double quote in text' do
        string = described_class.new('"')
        expected = Sass.compile_string('a { b: foo() }', functions: { 'foo()' => ->(_) { string } }).css
        actual = Sass.compile_string("a { b: #{string} }").css
        expect(actual).to eq(expected)

        expected = Sass.compile_string(expected).css
        expect(actual).to eq(expected)
      end

      it 'with single quote in text' do
        string = described_class.new("'")
        expected = Sass.compile_string('a { b: foo() }', functions: { 'foo()' => ->(_) { string } }).css
        actual = Sass.compile_string("a { b: #{string} }").css
        expect(actual).to eq(expected)

        expected = Sass.compile_string(expected).css
        expect(actual).to eq(expected)
      end

      it 'with double quote and single quote in text' do
        string = described_class.new('\'"')
        expected = Sass.compile_string('a { b: foo() }', functions: { 'foo()' => ->(_) { string } }).css
        actual = Sass.compile_string("a { b: #{string} }").css
        expect(actual).to eq(expected)

        expected = Sass.compile_string(expected).css
        expect(actual).to eq(expected)
      end

      it 'with special characters in text' do
        string = described_class.new((0..255).to_a.pack('U*'))
        expected = Sass.compile_string('a { b: foo() }', functions: { 'foo()' => ->(_) { string } }).css
        actual = Sass.compile_string("a { b: #{string} }").css
        expect(actual).to eq(expected.sub('\0', "\uFFFD"))

        expected = Sass.compile_string(expected).css
        expect(actual).to eq(expected)
      end
    end

    describe 'serialize unquoted string' do
      it 'without quote in text' do
        string = described_class.new('c', quoted: false)
        expected = Sass.compile_string('a { b: foo() }', functions: { 'foo()' => ->(_) { string } }).css
        actual = Sass.compile_string("a { b: #{string} }").css
        expect(actual).to eq(expected)

        expected = Sass.compile_string(expected).css
        expect(actual).to eq(expected)
      end

      it 'with double quote in text' do
        string = described_class.new('""', quoted: false)
        expected = Sass.compile_string('a { b: foo() }', functions: { 'foo()' => ->(_) { string } }).css
        actual = Sass.compile_string("a { b: #{string} }").css
        expect(actual).to eq(expected)

        expected = Sass.compile_string(expected).css
        expect(actual).to eq(expected)
      end

      it 'with single quote in text' do
        string = described_class.new("''", quoted: false)
        expected = Sass.compile_string('a { b: foo() }', functions: { 'foo()' => ->(_) { string } }).css
        actual = Sass.compile_string("a { b: #{string} }").css
        expect(actual).to eq(expected.tr("'", '"'))

        expected = Sass.compile_string(expected).css
        expect(actual).to eq(expected)
      end

      it 'with double quote and single quote in text' do
        string = described_class.new('"\'"', quoted: false)
        expected = Sass.compile_string('a { b: foo() }', functions: { 'foo()' => ->(_) { string } }).css
        actual = Sass.compile_string("a { b: #{string} }").css
        expect(actual).to eq(expected)

        expected = Sass.compile_string(expected).css
        expect(actual).to eq(expected)
      end

      it 'with newline followed by spaces in text' do
        string = described_class.new("a\nb\n c\n  d", quoted: false)
        expected = Sass.compile_string('a { b: foo() }', functions: { 'foo()' => ->(_) { string } }).css
        actual = Sass.compile_string("a { b: #{string} }").css
        expect(actual).to eq(expected)

        expected = Sass.compile_string(expected).css
        expect(actual).to eq(expected)
      end
    end
  end
end
