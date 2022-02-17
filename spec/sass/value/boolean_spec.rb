# frozen_string_literal: true

require 'spec_helper'

describe Sass::Value::Boolean do
  describe 'sassTrue' do
    value = Sass::Value::TRUE

    it 'is truthy' do
      expect(value.to_bool).to be(true)
    end

    it 'is sassTrue' do
      expect(value).to eq(Sass::Value::TRUE)
    end

    it 'is a value' do
      expect(value).to be_a(Sass::Value)
    end

    it 'is a boolean' do
      expect(value.assert_boolean).to eq(Sass::Value::TRUE)
    end

    it "isn't any other type" do
      expect { value.assert_color }.to raise_error(Sass::ScriptError)
      expect { value.assert_function }.to raise_error(Sass::ScriptError)
      expect { value.assert_map }.to raise_error(Sass::ScriptError)
      expect(value.to_map).to be(nil)
      expect { value.assert_number }.to raise_error(Sass::ScriptError)
      expect { value.assert_string }.to raise_error(Sass::ScriptError)
    end
  end

  describe 'sassFalse' do
    value = Sass::Value::FALSE

    it 'is falsey' do
      expect(value.to_bool).to be(false)
    end

    it 'is sassFalse' do
      expect(value).to eq(Sass::Value::FALSE)
    end

    it 'is a value' do
      expect(value).to be_a(Sass::Value)
    end

    it 'is a boolean' do
      expect(value.assert_boolean).to eq(Sass::Value::FALSE)
    end

    it "isn't any other type" do
      expect { value.assert_color }.to raise_error(Sass::ScriptError)
      expect { value.assert_function }.to raise_error(Sass::ScriptError)
      expect { value.assert_map }.to raise_error(Sass::ScriptError)
      expect(value.to_map).to be(nil)
      expect { value.assert_number }.to raise_error(Sass::ScriptError)
      expect { value.assert_string }.to raise_error(Sass::ScriptError)
    end
  end
end
