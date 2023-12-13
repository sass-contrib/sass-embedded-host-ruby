# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/null.test.ts
describe Sass::Value::Null do
  value = Sass::Value::Null::NULL

  it 'is falsey' do
    expect(value.to_bool).to be(false)
  end

  it 'returns nil in realNull check' do
    expect(value.to_nil).to be_nil
  end

  it 'is equal to itself' do
    expect(value).to eq(Sass::Value::Null::NULL)
  end

  it 'is a value' do
    expect(value).to be_a(Sass::Value)
  end

  it "isn't any type" do
    expect { value.assert_boolean }.to raise_error(Sass::ScriptError)
    expect { value.assert_calculation }.to raise_error(Sass::ScriptError)
    expect { value.assert_color }.to raise_error(Sass::ScriptError)
    expect { value.assert_function }.to raise_error(Sass::ScriptError)
    expect { value.assert_map }.to raise_error(Sass::ScriptError)
    expect(value.to_map).to be_nil
    expect { value.assert_mixin }.to raise_error(Sass::ScriptError)
    expect { value.assert_number }.to raise_error(Sass::ScriptError)
    expect { value.assert_string }.to raise_error(Sass::ScriptError)
  end
end
