# frozen_string_literal: true

require 'spec_helper'

describe Sass::Value::ArgumentList do
  it 'passes an argument list' do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(1)
      expect(args[0]).to be_a(described_class)
      arglist = args[0].to_a
      expect(arglist.length).to eq(3)
      expect(arglist.at(0).assert_string.text).to eq('x')
      expect(arglist.at(1).assert_string.text).to eq('y')
      expect(arglist.at(2).assert_string.text).to eq('z')
      Sass::Value::Null::NULL
    }

    expect(
      Sass.compile_string(
        'a {b: foo(x, y, z)}',
        functions: {
          'foo($arg...)': fn
        }
      ).css
    ).to eq('')

    expect(fn).to have_received(:call)
  end

  it 'passes keyword arguments' do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(1)
      expect(args[0]).to be_a(described_class)
      expect(args[0].to_a.length).to eq(0)
      keywords = args[0].keywords
      expect(keywords).to eq({
                               'bar' => Sass::Value::String.new('baz', quoted: false)
                             })
      Sass::Value::Null::NULL
    }

    expect(
      Sass.compile_string(
        'a {b: foo($bar: baz)}',
        functions: {
          'foo($arg...)': fn
        }
      ).css
    ).to eq('')

    expect(fn).to have_received(:call)
  end

  it "throws an error if arglist keywords aren't accessed" do
    fn = double
    allow(fn).to receive(:call) { |args|
      expect(args.length).to eq(1)
      expect(args[0]).to be_a(described_class)
      Sass::Value::Null::NULL
    }

    expect do
      Sass.compile_string(
        'a {b: foo($bar: baz)}',
        functions: {
          'foo($arg...)': fn
        }
      ).css
    end.to raise_error(an_instance_of(Sass::CompileError).and(
                         having_attributes(span: having_attributes(start: having_attributes(line: 0),
                                                                   url: nil))
                       ))

    expect(fn).to have_received(:call)
  end

  describe 'construction' do
    list = nil
    before do
      list = described_class.new(
        [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
        { 'd' => Sass::Value::String.new('e') }
      )
    end

    it 'is a value' do
      expect(list).to be_a(Sass::Value)
    end

    it 'is an argument list' do
      expect(list).to be_a(described_class)
    end

    it "isn't any other type" do
      expect { list.assert_boolean }.to raise_error(Sass::ScriptError)
      expect { list.assert_calculation }.to raise_error(Sass::ScriptError)
      expect { list.assert_color }.to raise_error(Sass::ScriptError)
      expect { list.assert_function }.to raise_error(Sass::ScriptError)
      expect { list.assert_map }.to raise_error(Sass::ScriptError)
      expect(list.to_map).to be_nil
      expect { list.assert_number }.to raise_error(Sass::ScriptError)
      expect { list.assert_string }.to raise_error(Sass::ScriptError)
    end

    it 'returns its contents as a list' do
      expect(list.to_a).to eq(
        [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')]
      )
    end

    it 'returns its keywords' do
      expect(list.keywords).to eq(
        { 'd' => Sass::Value::String.new('e') }
      )
    end
  end

  describe 'equality' do
    list = nil
    before do
      list = described_class.new(
        [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
        { 'd' => Sass::Value::String.new('e') }
      )
    end

    it 'equals the same argument list' do
      expect(list).to eq(
        described_class.new(
          [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
          { 'd' => Sass::Value::String.new('e') }
        )
      )
    end

    it 'equals an argument with only different keywords' do
      expect(list).to eq(
        described_class.new(
          [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
          { 'f' => Sass::Value::String.new('g') }
        )
      )
    end

    it 'equals a plain list with the same contents' do
      expect(list).to eq(
        Sass::Value::List.new(
          [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')]
        )
      )
    end

    it "doesn't equal an argument list with a different separator" do
      expect(list).not_to eq(
        described_class.new(
          [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
          {},
          ' '
        )
      )
    end
  end

  describe 'delimiters' do
    it 'defaults to comma separator and no brackets' do
      list = described_class.new(
        [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
        {}
      )
      expect(list.separator).to eq(',')
      expect(list.bracketed?).to be(false)
    end

    it 'allows an undecided separator for empty and single-element lists' do
      list = described_class.new([], {}, nil)
      expect(list.separator).to be_nil

      list = described_class.new([Sass::Value::String.new('a')], {}, nil)
      expect(list.separator).to be_nil
    end

    it 'does not allow an undecided separator for lists with more than one element' do
      expect do
        described_class.new(
          [Sass::Value::String.new('a'), Sass::Value::String.new('b')],
          {},
          nil
        )
      end.to raise_error(Sass::ScriptError)
    end

    it 'supports space separators' do
      list = described_class.new(
        [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
        {},
        ' '
      )
      expect(list.separator).to eq(' ')
    end

    it 'supports slash separators' do
      list = described_class.new(
        [Sass::Value::String.new('a'), Sass::Value::String.new('b'), Sass::Value::String.new('c')],
        {},
        '/'
      )
      expect(list.separator).to eq('/')
    end
  end
end
