# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/boolean.test.ts
describe Sass::Value::Boolean do
  describe 'sassTrue' do
    value = Sass::Value::Boolean::TRUE

    it 'is truthy' do
      expect(value.to_bool).to be(true)
    end

    it 'is sassTrue' do
      expect(value).to eq(Sass::Value::Boolean::TRUE)
    end

    it 'is a value' do
      expect(value).to be_a(Sass::Value)
    end

    it 'is a boolean' do
      expect(value.assert_boolean).to eq(Sass::Value::Boolean::TRUE)
    end

    it "isn't any other type" do
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

  describe 'sassFalse' do
    value = Sass::Value::Boolean::FALSE

    it 'is falsey' do
      expect(value.to_bool).to be(false)
    end

    it 'is sassFalse' do
      expect(value).to eq(Sass::Value::Boolean::FALSE)
    end

    it 'is a value' do
      expect(value).to be_a(Sass::Value)
    end

    it 'is a boolean' do
      expect(value.assert_boolean).to eq(Sass::Value::Boolean::FALSE)
    end

    it "isn't any other type" do
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
end
