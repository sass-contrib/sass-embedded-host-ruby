# frozen_string_literal: true

require 'spec_helper'

describe Sass::Value::Function do
  it 'can round-trip a function reference from Sass' do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(1)
      expect(args[0]).to be_a(described_class)
      args[0]
    }

    expect(
      Sass.compile_string("
                          @use 'sass:meta';

                          @function plusOne($n) {@return $n + 1}
                          a {b: meta.call(foo(meta.get-function('plusOne')), 2)}
                          ",
                          functions: {
                            'foo($arg)': fn
                          }).css
    ).to eq("a {\n  b: 3;\n}")

    expect(fn).to have_received(:call)
  end

  it 'can call a function reference from JS' do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(0)
      described_class.new('plusOne($n)', lambda { |args2|
        expect(args2.length).to eq(1)
        expect(args2[0].assert_number.value).to eq(2)
        Sass::Value::Number.new(args2[0].assert_number.value + 1)
      })
    }

    expect(
      Sass.compile_string("
                          @use 'sass:meta';

                          a {b: meta.call(foo(), 2)}
                          ",
                          functions: {
                            'foo()': fn
                          }).css
    ).to eq("a {\n  b: 3;\n}")

    expect(fn).to have_received(:call)
  end

  describe 'rejects a function signature that' do
    # Note that an implementation is allowed to throw an error either when the
    # function is instantiated *or* when it's returned from the custom function
    # callback. This test works in either case.
    {
      'is empty' => '',
      'has no name' => '()',
      'has no arguments' => 'foo',
      'has invalid arguments' => 'foo(arg)',
      'has an invalid default value' => 'foo($arg: <>)',
      'has no closing parenthesis' => 'foo(',
      'has a non-identifier name' => '$foo()'
    }.each do |scope, signature|
      it scope do
        fn = double
        allow(fn).to receive(:call) { |_args|
          described_class.new(signature, lambda { |_args2|
            Sass::Value::NULL
          })
        }

        expect do
          Sass.compile_string('a {b: inspect(foo())}',
                              functions: {
                                'foo()': fn
                              })
        end.to raise_error do |error|
          expect(error).to be_a(Sass::CompileError)
          expect(error.span.start.line).to eq(0)
          expect(error.span.url).to be_nil
        end

        expect(fn).to have_received(:call)
      end
    end
  end
end
