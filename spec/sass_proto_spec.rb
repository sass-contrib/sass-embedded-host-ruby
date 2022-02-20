# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sass do
  {
    __LINE__ => Sass::Value::String.new('a'),
    __LINE__ => Sass::Value::String.new('b', quoted: false),
    __LINE__ => Sass::Value::String.new('c', quoted: true),
    __LINE__ => Sass::Value::String.new('c', quoted: true),
    __LINE__ => Sass::Value::Number.new(Math::PI),
    __LINE__ => Sass::Value::Number.new(42, 'px'),
    __LINE__ => Sass::Value::Number.new(42, 'px', 'ms'),
    __LINE__ => Sass::Value::Color.new(red: 0, green: 0, blue: 0, alpha: 1),
    __LINE__ => Sass::Value::Color.new(hue: 0, saturation: 0, lightness: 0, alpha: 1),
    __LINE__ => Sass::Value::Color.new(hue: 0, whiteness: 0, blackness: 0, alpha: 1),
    __LINE__ => Sass::Value::List.new,
    __LINE__ => Sass::Value::List.new([Sass::Value::String.new('a')]),
    __LINE__ => Sass::Value::List.new([Sass::Value::String.new('a')], separator: ','),
    __LINE__ => Sass::Value::List.new([Sass::Value::String.new('a')], separator: '/'),
    __LINE__ => Sass::Value::List.new([Sass::Value::String.new('a')], separator: ' '),
    __LINE__ => Sass::Value::List.new([Sass::Value::String.new('a')], separator: nil),
    __LINE__ => Sass::Value::List.new([Sass::Value::String.new('a')], bracketed: true),
    __LINE__ => Sass::Value::List.new([Sass::Value::String.new('a')], bracketed: false),
    __LINE__ => Sass::Value::ArgumentList.new,
    __LINE__ => Sass::Value::ArgumentList.new([Sass::Value::String.new('a')]),
    __LINE__ => Sass::Value::ArgumentList.new([Sass::Value::String.new('a')], {}),
    __LINE__ => Sass::Value::ArgumentList.new(
      [Sass::Value::String.new('a')],
      {
        'a' => Sass::Value::String.new('b')
      }
    ),
    __LINE__ => Sass::Value::ArgumentList.new(
      [Sass::Value::String.new('a')],
      {
        'a' => Sass::Value::String.new('b'),
        'c' => Sass::Value::String.new('d')
      },
      ' '
    ),
    __LINE__ => Sass::Value::Map.new,
    __LINE__ => Sass::Value::Map.new(
      {
        Sass::Value::String.new('a') => Sass::Value::String.new('b')
      }
    ),
    __LINE__ => Sass::Value::Map.new(
      {
        Sass::Value::String.new('a') => Sass::Value::String.new('b'),
        Sass::Value::Number.new(1984) => Sass::Value::Null::NULL
      }
    ),
    __LINE__ => Sass::Value::Boolean::TRUE,
    __LINE__ => Sass::Value::Boolean::FALSE,
    __LINE__ => Sass::Value::Null::NULL
  }.each do |line, value|
    it "can round-trip #{value.class} from Sass (#{File.basename(__FILE__)}:#{line})" do
      foo = double
      allow(foo).to receive(:call) { |args|
        expect(args.length).to eq(1)
        expect(args[0]).to eq(value)
        expect(args[0].class).to eq(value.class)
        Sass::Value::Null::NULL
      }

      bar = double
      allow(bar).to receive(:call) { |args|
        expect(args.length).to eq(0)
        value
      }

      expect(
        described_class.compile_string('a {b: foo(bar())}',
                                       functions: {
                                         'foo($arg)': foo,
                                         'bar()': bar
                                       }).css
      ).to eq('')

      expect(foo).to have_received(:call)
      expect(bar).to have_received(:call)
    end
  end
end
