# frozen_string_literal: true

require 'spec_helper'

describe Sass::Value::Map do
  map = nil
  before do
    map = described_class.new({
                                Sass::Value::String.new('a') => Sass::Value::String.new('b'),
                                Sass::Value::String.new('c') => Sass::Value::String.new('d')
                              })
  end

  describe 'construction' do
    it 'is a value' do
      expect(map).to be_a(Sass::Value)
    end

    it 'is a map' do
      expect(map).to be_a(described_class)
      expect(map.assert_map).to be(map)
      expect(map.to_map).to be(map)
    end

    it "isn't any other type" do
      expect { map.assert_boolean }.to raise_error(Sass::ScriptError)
      expect { map.assert_calculation }.to raise_error(Sass::ScriptError)
      expect { map.assert_color }.to raise_error(Sass::ScriptError)
      expect { map.assert_function }.to raise_error(Sass::ScriptError)
      expect { map.assert_number }.to raise_error(Sass::ScriptError)
      expect { map.assert_string }.to raise_error(Sass::ScriptError)
    end

    it 'returns its contents as a map' do
      expect(map.contents)
        .to eq({
                 Sass::Value::String.new('a') => Sass::Value::String.new('b'),
                 Sass::Value::String.new('c') => Sass::Value::String.new('d')
               })
    end

    it 'returns its contents as a list' do
      expect(map.to_a)
        .to eq([
                 Sass::Value::List.new(
                   [Sass::Value::String.new('a'), Sass::Value::String.new('b')],
                   separator: ' '
                 ),
                 Sass::Value::List.new(
                   [Sass::Value::String.new('c'), Sass::Value::String.new('d')],
                   separator: ' '
                 )
               ])
    end

    it 'has a comma separator' do
      expect(map.separator).to eq(',')
    end
  end

  describe 'equality' do
    it 'equals the same map' do
      expect(map).to eq(
        described_class.new({
                              Sass::Value::String.new('a') => Sass::Value::String.new('b'),
                              Sass::Value::String.new('c') => Sass::Value::String.new('d')
                            })
      )
    end

    it 'equals the same map with a different ordering' do
      expect(map).to eq(
        described_class.new({
                              Sass::Value::String.new('c') => Sass::Value::String.new('d'),
                              Sass::Value::String.new('a') => Sass::Value::String.new('b')
                            })
      )
    end

    it "doesn't equal the equivalent list" do
      expect(map).not_to eq(
        Sass::Value::List.new(
          [
            Sass::Value::List.new([Sass::Value::String.new('a'), Sass::Value::String.new('b')],
                                  separator: ','),
            Sass::Value::List.new([Sass::Value::String.new('c'), Sass::Value::String.new('d')],
                                  separator: ',')
          ],
          separator: ','
        )
      )
    end

    describe "doesn't equal a map with" do
      it 'a different value' do
        expect(map).not_to eq(
          described_class.new({
                                Sass::Value::String.new('a') => Sass::Value::String.new('x'),
                                Sass::Value::String.new('c') => Sass::Value::String.new('d')
                              })
        )
      end

      it 'a different key' do
        expect(map).not_to eq(
          described_class.new({
                                Sass::Value::String.new('a') => Sass::Value::String.new('b'),
                                Sass::Value::String.new('x') => Sass::Value::String.new('d')
                              })
        )
      end

      it 'a missing pair' do
        expect(map).not_to eq(
          described_class.new({
                                Sass::Value::String.new('a') => Sass::Value::String.new('b')
                              })
        )
      end

      it 'an additional pair' do
        expect(map).not_to eq(
          described_class.new({
                                Sass::Value::String.new('a') => Sass::Value::String.new('b'),
                                Sass::Value::String.new('c') => Sass::Value::String.new('d'),
                                Sass::Value::String.new('e') => Sass::Value::String.new('f')
                              })
        )
      end
    end
  end

  describe 'Sass to Ruby index conversion()' do
    it 'converts a positive index' do
      expect(map.sass_index_to_array_index(Sass::Value::Number.new(1))).to eq(0)
      expect(map.sass_index_to_array_index(Sass::Value::Number.new(2))).to eq(1)
    end

    it 'converts a negative index' do
      expect(map.sass_index_to_array_index(Sass::Value::Number.new(-1))).to eq(1)
      expect(map.sass_index_to_array_index(Sass::Value::Number.new(-2))).to eq(0)
    end

    it 'rejects invalid indices' do
      expect { map.sass_index_to_array_index(Sass::Value::Number.new(0)) }.to raise_error(Sass::ScriptError)
      expect { map.sass_index_to_array_index(Sass::Value::Number.new(3)) }.to raise_error(Sass::ScriptError)
      expect { map.sass_index_to_array_index(Sass::Value::Number.new(-3)) }.to raise_error(Sass::ScriptError)
    end
  end

  describe 'at()' do
    map = nil
    before do
      map = described_class.new({
                                  Sass::Value::String.new('a') => Sass::Value::String.new('b'),
                                  Sass::Value::String.new('c') => Sass::Value::String.new('d')
                                })
    end

    describe 'with a number' do
      it 'returns elements for non-negative indices' do
        expect(map.at(0)).to eq(
          Sass::Value::List.new([Sass::Value::String.new('a'), Sass::Value::String.new('b')],
                                separator: ' ')
        )
        expect(map.at(1)).to eq(
          Sass::Value::List.new([Sass::Value::String.new('c'), Sass::Value::String.new('d')],
                                separator: ' ')
        )
      end

      it 'returns elements for negative indices' do
        expect(map.at(-2)).to eq(
          Sass::Value::List.new([Sass::Value::String.new('a'), Sass::Value::String.new('b')],
                                separator: ' ')
        )
        expect(map.at(-1)).to eq(
          Sass::Value::List.new([Sass::Value::String.new('c'), Sass::Value::String.new('d')],
                                separator: ' ')
        )
      end

      it 'returns nil for out-of-bounds values' do
        expect(map.at(2)).to be_nil
        expect(map.at(-3)).to be_nil
      end

      it 'rounds indices down' do
        expect(map.at(0.1)).to eq(
          Sass::Value::List.new([Sass::Value::String.new('a'), Sass::Value::String.new('b')],
                                separator: ' ')
        )
        expect(map.at(1.9)).to eq(
          Sass::Value::List.new([Sass::Value::String.new('c'), Sass::Value::String.new('d')],
                                separator: ' ')
        )
        expect(map.at(2.1)).to be_nil
        expect(map.at(-0.1)).to eq(
          Sass::Value::List.new([Sass::Value::String.new('c'), Sass::Value::String.new('d')],
                                separator: ' ')
        )
        expect(map.at(-1.9)).to eq(
          Sass::Value::List.new([Sass::Value::String.new('a'), Sass::Value::String.new('b')],
                                separator: ' ')
        )
        expect(map.at(-2.1)).to be_nil
      end
    end

    describe 'with a Value' do
      it 'returns values associated with keys' do
        expect(map.at(Sass::Value::String.new('a'))).to eq(
          Sass::Value::String.new('b')
        )
        expect(map.at(Sass::Value::String.new('c'))).to eq(
          Sass::Value::String.new('d')
        )
      end

      it 'returns undefined for keys that have no values' do
        expect(map.at(Sass::Value::String.new('b'))).to be_nil
        expect(map.at(Sass::Value::String.new('d'))).to be_nil
      end
    end
  end

  describe 'an empty map' do
    map = nil
    before do
      map = described_class.new
    end

    it 'has a nil separator' do
      expect(map.separator).to be_nil
    end

    it 'returns its contents as a map' do
      expect(map.contents).to be_empty
    end

    it 'returns its contents as a list' do
      expect(map.to_a).to be_empty
    end

    it 'equals another empty map' do
      expect(map).to eq(described_class.new({}))
      expect(map).to eq(described_class.new)
    end

    it 'equals an empty list' do
      expect(map).to eq(Sass::Value::List.new)
    end

    it 'rejects invalid indices' do
      expect { map.sass_index_to_array_index(Sass::Value::Number.new(0)) }.to raise_error(Sass::ScriptError)
      expect { map.sass_index_to_array_index(Sass::Value::Number.new(1)) }.to raise_error(Sass::ScriptError)
      expect { map.sass_index_to_array_index(Sass::Value::Number.new(-1)) }.to raise_error(Sass::ScriptError)
    end
  end
end
