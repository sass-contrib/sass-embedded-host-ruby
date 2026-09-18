# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/module.test.ts
describe Sass::Value::Module do
  it 'can round-trip a module reference from Sass' do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(1)
      value = args[0]

      expect(value).to be_a(described_class)
      expect { value.assert_boolean }.to raise_error(Sass::ScriptError)
      expect { value.assert_calculation }.to raise_error(Sass::ScriptError)
      expect { value.assert_color }.to raise_error(Sass::ScriptError)
      expect { value.assert_function }.to raise_error(Sass::ScriptError)
      expect { value.assert_map }.to raise_error(Sass::ScriptError)
      expect(value.to_map).to be_nil
      expect { value.assert_mixin }.to raise_error(Sass::ScriptError)
      expect(value.assert_module).to be(value)
      expect { value.assert_number }.to raise_error(Sass::ScriptError)
      expect { value.assert_string }.to raise_error(Sass::ScriptError)

      value
    }

    expect(
      Sass.compile_string(
        "
        @use 'sass:meta';
        a {b: meta.function-exists('function-exists', foo(meta.get-module('meta')))}
        ",
        functions: {
          'foo($arg)': ->(args) { fn.call(args) }
        }
      ).css
    ).to eq("a {\n  b: true;\n}")

    expect(fn).to have_received(:call)
  end

  it 'rejects a compiler module from a different compilation' do
    a = nil
    Sass.compile_string(
      "
      @use 'sass:meta';
      $_: foo(meta.get-module('meta'));
      ",
      functions: {
        'foo($arg)': ->(args) { a = args[0] }
      }
    )

    b = nil
    expect do
      Sass.compile_string(
        "
        @use 'sass:meta';
        $_: meta.module-variables(foo(meta.get-module('meta')));
        ",
        functions: {
          'foo($arg)': lambda { |args|
            b = args[0]
            a
          }
        }
      )
    end.to raise_sass_compile_error.with_line(2)

    expect(a).not_to eq(b)
  end
end
