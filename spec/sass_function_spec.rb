# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/function.test.ts
RSpec.describe Sass do
  it 'passes an argument to a custom function and uses its return value' do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(1)
      expect(args[0].assert_string.text).to eq('bar')
      Sass::Value::String.new('result')
    }

    expect(
      described_class.compile_string(
        'a {b: foo(bar)}',
        functions: {
          'foo($arg)': ->(args) { fn.call(args) }
        }
      ).css
    ).to eq("a {\n  b: \"result\";\n}")

    expect(fn).to have_received(:call)
  end

  it 'passes no arguments to a custom function' do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(0)
      Sass::Value::Null::NULL
    }

    expect(
      described_class.compile_string(
        'a {b: foo()}',
        functions: {
          'foo()': ->(args) { fn.call(args) }
        }
      ).css
    ).to eq('')

    expect(fn).to have_received(:call)
  end

  it 'passes multiple arguments to a custom function' do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(3)
      expect(args[0].assert_string.text).to eq('x')
      expect(args[1].assert_string.text).to eq('y')
      expect(args[2].assert_string.text).to eq('z')
      Sass::Value::Null::NULL
    }

    expect(
      described_class.compile_string(
        'a {b: foo(x, y, z)}',
        functions: {
          'foo($arg1, $arg2, $arg3)': ->(args) { fn.call(args) }
        }
      ).css
    ).to eq('')

    expect(fn).to have_received(:call)
  end

  it 'passes a default argument value' do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(1)
      expect(args[0].assert_string.text).to eq('default')
      Sass::Value::Null::NULL
    }

    expect(
      described_class.compile_string(
        'a {b: foo()}',
        functions: {
          'foo($arg: default)': ->(args) { fn.call(args) }
        }
      ).css
    ).to eq('')

    expect(fn).to have_received(:call)
  end

  describe 'gracefully handles a custom function' do
    it 'throwing' do
      expect do
        described_class.compile_string(
          'a {b: foo()}',
          functions: {
            'foo()': ->(_args) { raise 'heck' }
          }
        )
      end.to raise_sass_compile_error.with_line(0)
    end

    it 'not returning' do
      skip 'RBS::Test::Tester is loaded' if defined?(RBS::Test::Tester)

      expect do
        described_class.compile_string(
          'a {b: foo()}',
          functions: {
            'foo()': ->(_args) {}
          }
        )
      end.to raise_sass_compile_error.with_line(0)
    end

    describe 'returning a non-Value' do
      it 'directly' do
        skip 'RBS::Test::Tester is loaded' if defined?(RBS::Test::Tester)

        expect do
          described_class.compile_string(
            'a {b: foo()}',
            functions: {
              'foo()': ->(_args) { 'wrong' }
            }
          )
        end.to raise_sass_compile_error.with_line(0)
      end

      it 'in a calculation' do
        expect do
          described_class.compile_string(
            'a {b: foo()}',
            functions: {
              'foo()': ->(_args) { Sass::Value::Calculation.calc('wrong') }
            }
          )
        end.to raise_sass_compile_error.with_line(0)
      end
    end
  end

  describe 'dash-normalizes function calls' do
    it 'when defined with dashes' do
      fn = double
      allow(fn).to receive(:call).and_return(Sass::Value::Null::NULL)

      expect(
        described_class.compile_string(
          'a {b: foo_bar()}',
          functions: {
            'foo-bar()': ->(args) { fn.call(args) }
          }
        ).css
      ).to eq('')

      expect(fn).to have_received(:call)
    end

    it 'when defined with underscores' do
      fn = double
      allow(fn).to receive(:call).and_return(Sass::Value::Null::NULL)

      expect(
        described_class.compile_string(
          'a {b: foo-bar()}',
          functions: {
            'foo_bar()': ->(args) { fn.call(args) }
          }
        ).css
      ).to eq('')

      expect(fn).to have_received(:call)
    end
  end

  describe 'rejects a function signature that' do
    it 'is empty' do
      expect do
        described_class.compile_string('', functions: { '': ->(_args) { Sass::Value::Null::NULL } })
      end.to raise_sass_compile_error
    end

    it 'has no name' do
      expect do
        described_class.compile_string('', functions: { '()': ->(_args) { Sass::Value::Null::NULL } })
      end.to raise_sass_compile_error
    end

    it 'has no arguments' do
      expect do
        described_class.compile_string('', functions: { foo: ->(_args) { Sass::Value::Null::NULL } })
      end.to raise_sass_compile_error
    end

    it 'has invalid arguments' do
      expect do
        described_class.compile_string('', functions: { 'foo(arg)': ->(_args) { Sass::Value::Null::NULL } })
      end.to raise_sass_compile_error
    end

    it 'has no closing parentheses' do
      expect do
        described_class.compile_string('', functions: { 'foo(': ->(_args) { Sass::Value::Null::NULL } })
      end.to raise_sass_compile_error
    end

    it 'has a non-identifier name' do
      expect do
        described_class.compile_string('', functions: { '$foo()': ->(_args) { Sass::Value::Null::NULL } })
      end.to raise_sass_compile_error
    end

    it 'has whitespace before the signature' do
      expect do
        described_class.compile_string('', functions: { ' foo()': ->(_args) { Sass::Value::Null::NULL } })
      end.to raise_sass_compile_error
    end

    it 'has whitespace after the signature' do
      expect do
        described_class.compile_string('', functions: { 'foo() ': ->(_args) { Sass::Value::Null::NULL } })
      end.to raise_sass_compile_error
    end

    it 'has whitespace between the identifier and the arguments' do
      expect do
        described_class.compile_string('', functions: { 'foo ()': ->(_args) { Sass::Value::Null::NULL } })
      end.to raise_sass_compile_error
    end
  end
end
