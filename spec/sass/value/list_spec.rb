# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/list.test.ts
describe Sass::Value::List do
  describe 'construction' do
    list = nil
    before do
      list = described_class.new(
        [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
        separator: ','
      )
    end

    it 'is a value' do
      expect(list).to be_a(Sass::Value)
    end

    it "isn't any other type" do
      expect { list.assert_boolean }.to raise_error(Sass::ScriptError)
      expect { list.assert_calculation }.to raise_error(Sass::ScriptError)
      expect { list.assert_color }.to raise_error(Sass::ScriptError)
      expect { list.assert_function }.to raise_error(Sass::ScriptError)
      expect { list.assert_map }.to raise_error(Sass::ScriptError)
      expect(list.to_map).to be_nil
      expect { list.assert_mixin }.to raise_error(Sass::ScriptError)
      expect { list.assert_number }.to raise_error(Sass::ScriptError)
      expect { list.assert_string }.to raise_error(Sass::ScriptError)
    end

    it 'returns its contents as a list' do
      expect(list.to_a)
        .to eq([Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')])
    end
  end

  describe 'equality' do
    list = nil
    before do
      list = described_class.new(
        [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
        separator: ','
      )
    end

    it 'equals the same list' do
      expect(list).to eq(
        described_class.new(
          [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
          separator: ','
        )
      )
    end

    it "doesn't equal the same list with a different ordering" do
      expect(list).not_to eq(
        described_class.new(
          [Sass::Value::String.new('c'), Sass::Value::String.new('b'), Sass::Value::String.new('a')],
          separator: ','
        )
      )
    end

    it "doesn't equal a list with different metadata" do
      expect(list).not_to eq(
        described_class.new(
          [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
          separator: ' '
        )
      )
      expect(list).not_to eq(
        described_class.new(
          [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
          separator: ',', bracketed: true
        )
      )
    end

    it "doesn't equal a list with different contents" do
      expect(list).not_to eq(
        described_class.new(
          [Sass::Value::String.new('a'), Sass::Value::String.new('x'), Sass::Value::String.new('c')],
          separator: ',', bracketed: true
        )
      )
    end

    it "doesn't equal a list with a missing entry" do
      expect(list).not_to eq(
        described_class.new(
          [Sass::Value::String.new('a'), Sass::Value::String.new('b')],
          separator: ','
        )
      )
    end

    it "doesn't equal a list with an additional entry" do
      expect(list).not_to eq(
        described_class.new(
          [
            Sass::Value::String.new('a'),
            Sass::Value::String.new('b'),
            Sass::Value::String.new('c'),
            Sass::Value::String.new('d')
          ],
          separator: ','
        )
      )
    end
  end

  describe 'Sass to Ruby index conversion' do
    list = nil
    before do
      list = described_class.new(
        [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')]
      )
    end

    it 'converts a positive index' do
      expect(list.sass_index_to_array_index(Sass::Value::Number.new(1))).to be(0)
      expect(list.sass_index_to_array_index(Sass::Value::Number.new(2))).to be(1)
      expect(list.sass_index_to_array_index(Sass::Value::Number.new(3))).to be(2)
    end

    it 'converts a negative index' do
      expect(list.sass_index_to_array_index(Sass::Value::Number.new(-1))).to be(2)
      expect(list.sass_index_to_array_index(Sass::Value::Number.new(-2))).to be(1)
      expect(list.sass_index_to_array_index(Sass::Value::Number.new(-3))).to be(0)
    end

    it 'rejects a non-number' do
      expect { list.sass_index_to_array_index(Sass::Value::String.new('foo')) }.to raise_error(Sass::ScriptError)
    end

    it 'rejects a non-integer' do
      expect { list.sass_index_to_array_index(Sass::Value::Number.new(1.1)) }.to raise_error(Sass::ScriptError)
    end

    it 'rejects invalid indices' do
      expect { list.sass_index_to_array_index(Sass::Value::Number.new(0)) }.to raise_error(Sass::ScriptError)
      expect { list.sass_index_to_array_index(Sass::Value::Number.new(4)) }.to raise_error(Sass::ScriptError)
      expect { list.sass_index_to_array_index(Sass::Value::Number.new(-4)) }.to raise_error(Sass::ScriptError)
    end
  end

  describe 'delimiters' do
    it 'defaults to comma separator and no brackets' do
      list = described_class.new(
        [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')]
      )
      expect(list.separator).to eq(',')
      expect(list.bracketed?).to be(false)
    end

    it 'allows an undecided separator for empty and single-element lists' do
      list = described_class.new(separator: nil)
      expect(list.separator).to be_nil
      list = described_class.new([Sass::Value::String.new('a')], separator: nil)
      expect(list.separator).to be_nil
    end

    it 'does not allow an undecided separator for lists with more than one element' do
      expect do
        described_class.new(
          [Sass::Value::String.new('a'), Sass::Value::String.new('b')],
          separator: nil
        )
      end.to raise_error(Sass::ScriptError)
    end

    it 'supports space separators' do
      list = described_class.new(
        [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
        separator: ' '
      )
      expect(list.separator).to eq(' ')
    end

    it 'supports slash separators' do
      list = described_class.new(
        [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
        separator: '/'
      )
      expect(list.separator).to eq('/')
    end

    it 'supports brackets' do
      list = described_class.new(
        [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
        bracketed: true
      )
      expect(list.bracketed?).to be(true)
    end
  end

  describe 'at()' do
    list = nil
    before do
      list = described_class.new(
        [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')]
      )
    end

    it 'returns elements for non-negative indices' do
      expect(list.at(0)).to eq(Sass::Value::String.new('a'))
      expect(list.at(1)).to eq(Sass::Value::String.new('b'))
      expect(list.at(2)).to eq(Sass::Value::String.new('c'))
    end

    it 'returns elements for negative indices' do
      expect(list.at(-3)).to eq(Sass::Value::String.new('a'))
      expect(list.at(-2)).to eq(Sass::Value::String.new('b'))
      expect(list.at(-1)).to eq(Sass::Value::String.new('c'))
    end

    it 'returns nil for out-of-bounds values' do
      expect(list.at(3)).to be_nil
      expect(list.at(-4)).to be_nil
    end

    it 'rounds indices down' do
      expect(list.at(0.1)).to eq(Sass::Value::String.new('a'))
      expect(list.at(2.9)).to eq(Sass::Value::String.new('c'))
      expect(list.at(3.1)).to be_nil
      expect(list.at(-0.1)).to eq(Sass::Value::String.new('c'))
      expect(list.at(-2.9)).to eq(Sass::Value::String.new('a'))
      expect(list.at(3.1)).to be_nil
    end
  end

  describe 'single-element list' do
    list = nil
    before do
      list = described_class.new([Sass::Value::Number.new(1)])
    end

    it 'has a comma separator' do
      expect(list.separator).to eq(',')
    end

    it 'has no brackets' do
      expect(list.bracketed?).to be(false)
    end

    it 'returns its contents as a list' do
      expect(list.to_a).to eq([Sass::Value::Number.new(1)])
    end
  end

  describe 'a scalar value' do
    string = nil
    before do
      string = Sass::Value::String.new('blue')
    end

    it 'has an undecided separator' do
      expect(string.separator).to be_nil
    end

    it 'returns itself as a list' do
      list = string.to_a
      expect(list.length).to eq(1)
      expect(list.at(0)).to be(string)
    end

    describe 'Sass to Ruby index conversion' do
      it 'converts a positive index' do
        expect(string.sass_index_to_array_index(Sass::Value::Number.new(1))).to eq(0)
      end

      it 'converts a negative index' do
        expect(string.sass_index_to_array_index(Sass::Value::Number.new(-1))).to eq(0)
      end

      it 'rejects invalid indices' do
        expect { string.sass_index_to_array_index(Sass::Value::Number.new(0)) }.to raise_error(Sass::ScriptError)
        expect { string.sass_index_to_array_index(Sass::Value::Number.new(2)) }.to raise_error(Sass::ScriptError)
        expect { string.sass_index_to_array_index(Sass::Value::Number.new(-2)) }.to raise_error(Sass::ScriptError)
      end
    end

    describe 'at()' do
      it 'returns the value for index 0' do
        expect(string.at(0)).to eq(string)
      end

      it 'returns the value for index -1' do
        expect(string.at(-1)).to eq(string)
      end

      it 'returns nil for out-of-bounds values' do
        expect(string.at(1)).to be_nil
        expect(string.at(-2)).to be_nil
      end

      it 'rounds indices down' do
        expect(string.at(0.1)).to eq(string)
        expect(string.at(1.9)).to be_nil
        expect(string.at(-0.1)).to eq(string)
        expect(string.at(-1.9)).to be_nil
      end
    end
  end

  describe 'an empty list' do
    list = nil
    before do
      list = described_class.new
    end

    it 'defaults to a comma separator' do
      expect(list.separator).to eq(',')
    end

    it 'has no brackets' do
      expect(list.bracketed?).to be(false)
    end

    it 'returns its contents as a list' do
      expect(list.to_a).to be_empty
    end

    it 'equals another empty list' do
      expect(list).to eq(described_class.new([]))
      expect(list).to eq(described_class.new)
    end

    it 'counts as an empty map' do
      expect(list.assert_map.contents).to be_empty
      expect(list.to_map.contents).to be_empty
    end

    it "isn't any other type" do
      expect { list.assert_boolean }.to raise_error(Sass::ScriptError)
      expect { list.assert_color }.to raise_error(Sass::ScriptError)
      expect { list.assert_function }.to raise_error(Sass::ScriptError)
      expect { list.assert_number }.to raise_error(Sass::ScriptError)
      expect { list.assert_string }.to raise_error(Sass::ScriptError)
    end

    it 'rejects invalid indices' do
      expect { list.sass_index_to_array_index(Sass::Value::Number.new(0)) }.to raise_error(Sass::ScriptError)
      expect { list.sass_index_to_array_index(Sass::Value::Number.new(1)) }.to raise_error(Sass::ScriptError)
      expect { list.sass_index_to_array_index(Sass::Value::Number.new(-1)) }.to raise_error(Sass::ScriptError)
    end

    it 'at() always returns nil' do
      expect(list.at(0)).to be_nil
      expect(list.at(1)).to be_nil
      expect(list.at(-1)).to be_nil
    end
  end
end
