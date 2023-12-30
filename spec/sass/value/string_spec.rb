# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/string.test.ts
describe Sass::Value::String do
  describe 'construction' do
    it 'creates a quoted string with the given text' do
      string = described_class.new('nb', quoted: true)
      expect(string.text).to eq('nb')
      expect(string.quoted?).to be(true)
    end

    it 'creates an unquoted string with the given text' do
      string = described_class.new('nb', quoted: false)
      expect(string.text).to eq('nb')
      expect(string.quoted?).to be(false)
    end

    it 'creates an empty quoted string' do
      string = described_class.new(quoted: true)
      expect(string.text).to eq('')
      expect(string.quoted?).to be(true)
    end

    it 'creates an empty unquoted string' do
      string = described_class.new(quoted: false)
      expect(string.text).to eq('')
      expect(string.quoted?).to be(false)
    end

    it 'an empty string defaults to being quoted' do
      string = described_class.new
      expect(string.text).to eq('')
      expect(string.quoted?).to be(true)
    end

    it 'is equal to the same string' do
      string = described_class.new('nb', quoted: true)
      expect(string).to eq(described_class.new('nb', quoted: false))
    end

    it 'is a value' do
      expect(described_class.new('nb')).to be_a(Sass::Value)
    end

    it 'is a string' do
      value = described_class.new('nb')
      expect(value).to be_a(described_class)
      expect { value.assert_string }.not_to raise_error
    end

    it "isn't any other type" do
      value = described_class.new('nb')
      expect { value.assert_boolean }.to raise_error(Sass::ScriptError)
      expect { value.assert_calculation }.to raise_error(Sass::ScriptError)
      expect { value.assert_color }.to raise_error(Sass::ScriptError)
      expect { value.assert_function }.to raise_error(Sass::ScriptError)
      expect { value.assert_map }.to raise_error(Sass::ScriptError)
      expect(value.to_map).to be_nil
      expect { value.assert_mixin }.to raise_error(Sass::ScriptError)
      expect { value.assert_number }.to raise_error(Sass::ScriptError)
    end
  end

  describe 'index handling' do
    let(:string) do
      described_class.new('nb')
    end

    it 'rejects a zero index' do
      expect { string.sass_index_to_string_index(Sass::Value::Number.new(0)) }.to raise_error(Sass::ScriptError)
    end

    it 'rejects a non-integer index' do
      expect { string.sass_index_to_string_index(Sass::Value::Number.new(0.1)) }.to raise_error(Sass::ScriptError)
    end

    it 'rejects a non-SassNumber index' do
      expect { string.sass_index_to_string_index(described_class.new('1')) }.to raise_error(Sass::ScriptError)
    end

    describe 'ASCII' do
      let(:string) do
        described_class.new('nb')
      end

      it 'converts a positive index' do
        expect(string.sass_index_to_string_index(Sass::Value::Number.new(1))).to eq(0)
        expect(string.sass_index_to_string_index(Sass::Value::Number.new(2))).to eq(1)
      end

      it 'converts a negative index' do
        expect(string.sass_index_to_string_index(Sass::Value::Number.new(-1))).to eq(1)
        expect(string.sass_index_to_string_index(Sass::Value::Number.new(-2))).to eq(0)
      end

      it 'rejects out of bound indices' do
        expect { string.sass_index_to_string_index(Sass::Value::Number.new(3)) }.to raise_error(Sass::ScriptError)
        expect { string.sass_index_to_string_index(Sass::Value::Number.new(-3)) }.to raise_error(Sass::ScriptError)
      end
    end

    describe 'Unicode' do
      let(:string) do
        described_class.new('a👭b👬c')
      end

      it 'converts a positive index' do
        expect(string.sass_index_to_string_index(Sass::Value::Number.new(1))).to eq(0)
        expect(string.sass_index_to_string_index(Sass::Value::Number.new(2))).to eq(1)
        expect(string.sass_index_to_string_index(Sass::Value::Number.new(3))).to eq(2)
        expect(string.sass_index_to_string_index(Sass::Value::Number.new(4))).to eq(3)
        expect(string.sass_index_to_string_index(Sass::Value::Number.new(5))).to eq(4)
      end

      it 'converts a negative index' do
        expect(string.sass_index_to_string_index(Sass::Value::Number.new(-1))).to eq(4)
        expect(string.sass_index_to_string_index(Sass::Value::Number.new(-2))).to eq(3)
        expect(string.sass_index_to_string_index(Sass::Value::Number.new(-3))).to eq(2)
        expect(string.sass_index_to_string_index(Sass::Value::Number.new(-4))).to eq(1)
        expect(string.sass_index_to_string_index(Sass::Value::Number.new(-5))).to eq(0)
      end

      it 'rejects out of bound indices' do
        expect { string.sass_index_to_string_index(Sass::Value::Number.new(6)) }.to raise_error(Sass::ScriptError)
        expect { string.sass_index_to_string_index(Sass::Value::Number.new(-6)) }.to raise_error(Sass::ScriptError)
      end
    end
  end
end
