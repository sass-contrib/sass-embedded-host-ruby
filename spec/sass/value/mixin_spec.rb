# frozen_string_literal: true

require 'spec_helper'

describe Sass::Value::Mixin do
  it 'can round-trip a mixin reference from Sass' do
    skip 'TODO: enable after dart-sass release'

    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(1)
      expect(args[0]).to be_a(described_class)
      args[0]
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
          'foo($arg)': fn
        }
      ).css
    ).to eq("a {\n  b: c;\n}")

    expect(fn).to have_received(:call)
  end
end
