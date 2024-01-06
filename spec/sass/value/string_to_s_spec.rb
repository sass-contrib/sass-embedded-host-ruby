# frozen_string_literal: true

require 'spec_helper'

describe Sass::Value::String do
  describe '.to_s' do
    describe 'serialize quoted string' do
      let(:whitespace) do
        " \t\r\n\v\f".chars.repeated_permutation(3).map(&:join)
      end

      let(:cntrl) do
        [*"\x01".."\x1F", "\x7F"].repeated_permutation(2).map(&:join)
      end

      {
        'without quote or backslash in text' => 'c',
        'with double quote in text' => '"',
        'with single quote in text' => "'",
        'with double quote and single quote in text' => '\'"',
        'with more double quote than single quote in text' => '"\'"',
        'with more single quote than double quote in text' => "'\"'",
        'with backslash in text' => '\\',
        'with [[:space:]] in text' => proc { whitespace.join },
        'with [[:space:]] followed by [[:alpha:]] in text' => proc { whitespace.join('x') },
        'with [[:space:]] followed by [[:xdigit:]] in text' => proc { whitespace.join('c') },
        'with [[:cntrl:]] in text' => proc { cntrl.join },
        'with [[:cntrl:]] followed by [[:alpha:]] in text' => proc { cntrl.join('x') },
        'with [[:cntrl:]] followed by [[:xdigit:]] in text' => proc { cntrl.join('c') },
        'with [[:ascii:]] in text' => [*"\1".."\x7F"].join
      }.each do |doc_string, subject_string|
        it doc_string do
          string = described_class.new(subject_string.is_a?(Proc) ? instance_eval(&subject_string) : subject_string)
          expected = Sass.compile_string('a { b: foo() }',
                                         charset: false,
                                         style: :compressed,
                                         functions: { 'foo()' => ->(_) { string } }).css
          actual = "a{b:#{string}}"
          expect(actual).to eq(expected)
          expect(actual).to eq(Sass.compile_string(actual, charset: false, style: :compressed).css)

          result = nil
          Sass.compile_string("$_: yield(#{string});",
                              functions: {
                                'yield($value)' => lambda { |args|
                                  result = args[0].assert_string
                                  Sass::Value::Null::NULL
                                }
                              })
          expect(result).to eq(string)
        end
      end
    end

    describe 'serialize unquoted string' do
      {
        'without quote or backslash in text': 'c',
        'with double quote in text': 'url("a")',
        'with single quote in text': "url('b')",
        'with double quote and single quote in text': 'url("\'")',
        'without backslash in text': '\\',
        'with newline followed by space in text': " \n".chars.repeated_permutation(3).map(&:join).join('x')
      }.each do |doc_string, subject_string|
        it doc_string do
          string = described_class.new(subject_string, quoted: false)
          expected = Sass.compile_string('a { b: foo() }', functions: { 'foo()' => ->(_) { string } }).css
          actual = "a {\n  b: #{string};\n}"
          expect(actual).to eq(expected)
        end
      end
    end
  end
end
