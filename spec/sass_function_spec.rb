# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sass do
  it 'passes an argument to a custom function and uses its return value' do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(1)
      expect(args[0].assert_string.text).to eq('bar')
      Sass::Value::String.new('result')
    }

    expect(
      described_class.compile_string('a {b: foo(bar)}',
                                     functions: {
                                       'foo($arg)': fn
                                     }).css
    ).to eq("a {\n  b: \"result\";\n}")

    expect(fn).to have_received(:call)
  end

  it 'passes no arguments to a custom function' do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(0)
      Sass::Value::NULL
    }

    expect(
      described_class.compile_string('a {b: foo()}',
                                     functions: {
                                       'foo()': fn
                                     }).css
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
      Sass::Value::NULL
    }

    expect(
      described_class.compile_string('a {b: foo(x, y, z)}',
                                     functions: {
                                       'foo($arg1, $arg2, $arg3)': fn
                                     }).css
    ).to eq('')

    expect(fn).to have_received(:call)
  end

  it 'passes a default argument value' do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(1)
      expect(args[0].assert_string.text).to eq('default')
      Sass::Value::NULL
    }

    expect(
      described_class.compile_string('a {b: foo()}',
                                     functions: {
                                       'foo($arg: default)': fn
                                     }).css
    ).to eq('')

    expect(fn).to have_received(:call)
  end

  describe 'gracefully handles a custom function' do
    it 'throwing' do
      expect do
        described_class.compile_string('a {b: foo()}',
                                       functions: {
                                         'foo()': -> { raise 'heck' }
                                       })
      end.to raise_error do |error|
        expect(error).to be_a(Sass::CompileError)
        expect(error.span.start.line).to eq(0)
      end
    end

    it 'not returning' do
      expect do
        described_class.compile_string('a {b: foo()}',
                                       functions: {
                                         'foo()': -> {}
                                       })
      end.to raise_error do |error|
        expect(error).to be_a(Sass::CompileError)
        expect(error.span.start.line).to eq(0)
      end
    end

    it 'returning a non-Value' do
      expect do
        described_class.compile_string('a {b: foo()}',
                                       functions: {
                                         'foo()': -> { 'wrong' }
                                       })
      end.to raise_error do |error|
        expect(error).to be_a(Sass::CompileError)
        expect(error.span.start.line).to eq(0)
      end
    end
  end

  describe 'dash-normalizes function calls' do
    it 'when defined with dashes' do
      fn = double
      allow(fn).to receive(:call).and_return(Sass::Value::NULL)

      expect(
        described_class.compile_string('a {b: foo_bar()}',
                                       functions: {
                                         'foo-bar()': fn
                                       }).css
      ).to eq('')

      expect(fn).to have_received(:call)
    end

    it 'when defined with underscores' do
      fn = double
      allow(fn).to receive(:call).and_return(Sass::Value::NULL)

      expect(
        described_class.compile_string('a {b: foo-bar()}',
                                       functions: {
                                         'foo_bar()': fn
                                       }).css
      ).to eq('')

      expect(fn).to have_received(:call)
    end
  end

  describe 'rejects a function signature that' do
    it 'is empty' do
      expect do
        described_class.compile_string('', functions: { '': -> { Sass::Value::NULL } })
      end.to raise_error(Sass::Embedded::ProtocolError)
    end

    it 'has no name' do
      expect do
        described_class.compile_string('', functions: { '()': -> { Sass::Value::NULL } })
      end.to raise_error(Sass::Embedded::ProtocolError)
    end

    it 'has no arguments' do
      expect do
        described_class.compile_string('', functions: { foo: -> { Sass::Value::NULL } })
      end.to raise_error(Sass::Embedded::ProtocolError)
    end

    it 'has invalid arguments' do
      expect do
        described_class.compile_string('', functions: { 'foo(arg)': -> { Sass::Value::NULL } })
      end.to raise_error(Sass::Embedded::ProtocolError)
    end

    it 'has no closing parentheses' do
      expect do
        described_class.compile_string('', functions: { 'foo(': -> { Sass::Value::NULL } })
      end.to raise_error(Sass::Embedded::ProtocolError)
    end

    it 'has a non-identifier name' do
      expect do
        described_class.compile_string('', functions: { '$foo()': -> { Sass::Value::NULL } })
      end.to raise_error(Sass::Embedded::ProtocolError)
    end
  end
end
