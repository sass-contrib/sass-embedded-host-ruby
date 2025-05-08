# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/function.test.ts
describe Sass::Value::Function do
  it 'can round-trip a function reference from Sass' do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(1)
      value = args[0]

      expect(value).to be_a(described_class)
      expect { value.assert_boolean }.to raise_error(Sass::ScriptError)
      expect { value.assert_calculation }.to raise_error(Sass::ScriptError)
      expect { value.assert_color }.to raise_error(Sass::ScriptError)
      expect(value.assert_function).to be(value)
      expect { value.assert_map }.to raise_error(Sass::ScriptError)
      expect(value.to_map).to be_nil
      expect { value.assert_mixin }.to raise_error(Sass::ScriptError)
      expect { value.assert_number }.to raise_error(Sass::ScriptError)
      expect { value.assert_string }.to raise_error(Sass::ScriptError)

      value
    }

    expect(
      Sass.compile_string(
        "
        @use 'sass:meta';

        @function plusOne($n) {@return $n + 1}
        a {b: meta.call(foo(meta.get-function('plusOne')), 2)}
        ",
        functions: {
          'foo($arg)': ->(args) { fn.call(args) }
        }
      ).css
    ).to eq("a {\n  b: 3;\n}")

    expect(fn).to have_received(:call)
  end

  it 'can call a function reference from Ruby' do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(0)
      described_class.new('plusOne($n)') do |arguments|
        expect(arguments.length).to eq(1)
        expect(arguments[0].assert_number.value).to eq(2)
        Sass::Value::Number.new(arguments[0].assert_number.value + 1)
      end
    }

    expect(
      Sass.compile_string(
        "
        @use 'sass:meta';

        a {b: meta.call(foo(), 2)}
        ",
        functions: {
          'foo()': ->(args) { fn.call(args) }
        }
      ).css
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
        allow(fn).to receive(:call) { |*|
          described_class.new(signature) { |*| Sass::Value::Null::NULL }
        }

        expect do
          Sass.compile_string(
            'a {b: inspect(foo())}',
            functions: {
              'foo()': ->(args) { fn.call(args) }
            }
          )
        end.to raise_sass_compile_error.with_line(0).without_url

        expect(fn).to have_received(:call)
      end
    end
  end

  it 'rejects a compiler function from a different compilation' do
    plus_one = nil
    Sass.compile_string(
      "
      @use 'sass:meta';

      @function plusOne($n) {@return $n + 1}
      a {b: meta.call(foo(meta.get-function('plusOne')), 2)}
      ",
      functions: {
        'foo($arg)': ->(args) { plus_one = args[0] }
      }
    )

    plus_two = nil
    expect do
      Sass.compile_string(
        "
        @use 'sass:meta';

        @function plusTwo($n) {@return $n + 2}
        a {b: meta.call(foo(meta.get-function('plusTwo')), 2)}
        ",
        functions: {
          'foo($arg)': lambda { |args|
            plus_two = args[0]
            plus_one
          }
        }
      )
    end.to raise_sass_compile_error.with_line(4)

    expect(plus_one).not_to eq(plus_two)
  end
end
