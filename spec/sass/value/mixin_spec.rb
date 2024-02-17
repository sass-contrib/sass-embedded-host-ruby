# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/mixin.test.ts
describe Sass::Value::Mixin do
  it 'can round-trip a mixin reference from Sass' do
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
      expect(value.assert_mixin).to be(value)
      expect { value.assert_number }.to raise_error(Sass::ScriptError)
      expect { value.assert_string }.to raise_error(Sass::ScriptError)

      value
    }

    expect(
      Sass.compile_string(
        "
        @use 'sass:meta';

        @mixin a() {
          a {
            b: c;
          }
        }

        @include meta.apply(foo(meta.get-mixin('a')));
        ",
        functions: {
          'foo($arg)': ->(args) { fn.call(args) }
        }
      ).css
    ).to eq("a {\n  b: c;\n}")

    expect(fn).to have_received(:call)
  end
end
