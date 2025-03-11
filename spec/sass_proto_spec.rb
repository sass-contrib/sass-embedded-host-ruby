# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sass do
  def remote_eq(lhs, rhs)
    result = nil
    Sass.compile_string(
      '$_: yield(lhs()==rhs());',
      functions: {
        'yield($value)' => lambda { |args|
          result = args[0].assert_boolean.to_bool
          Sass::Value::Null::NULL
        },
        'lhs()' => lambda { |*|
          lhs
        },
        'rhs()' => lambda { |*|
          rhs
        }
      }
    )
    result
  end

  {
    __LINE__ => Sass::Value::String.new('a'),
    __LINE__ => Sass::Value::String.new('b', quoted: false),
    __LINE__ => Sass::Value::String.new('c', quoted: true),
    __LINE__ => Sass::Value::String.new('c', quoted: true),
    __LINE__ => Sass::Value::Number.new(Math::PI),
    __LINE__ => Sass::Value::Number.new(42, 'px'),
    __LINE__ => Sass::Value::Number.new(42, { numerator_units: ['px'], denominator_units: ['ms'] }),
    __LINE__ => Sass::Value::Calculation.calc(
      Sass::CalculationValue::CalculationOperation.new(
        '+',
        Sass::Value::Number.new(1, 'em'),
        Sass::Value::Number.new(42, 'px')
      )
    ),
    __LINE__ => Sass::Value::Calculation.min([
                                               Sass::Value::Number.new(1, 'em'),
                                               Sass::Value::Number.new(42, 'px'),
                                               Sass::Value::Calculation.max([
                                                                              Sass::Value::Number.new(1, 'rem'),
                                                                              Sass::Value::Number.new(42, 'pt')
                                                                            ])
                                             ]),
    __LINE__ => Sass::Value::Calculation.max([
                                               Sass::Value::String.new('1', quoted: false),
                                               Sass::Value::Number.new(42, 'px'),
                                               Sass::Value::Calculation.min([
                                                                              Sass::Value::Number.new(1, 'rem'),
                                                                              Sass::Value::Number.new(42, 'pt')
                                                                            ])
                                             ]),
    __LINE__ => Sass::Value::Calculation.clamp(Sass::Value::String.new('var(--clamp)', quoted: false)),
    __LINE__ => Sass::Value::Color.new(red: 0.1, green: 0.2, blue: nil, alpha: 1, space: 'rgb'),
    __LINE__ => Sass::Value::Color.new(hue: 0.4, saturation: nil, lightness: 0.6, alpha: 1, space: 'hsl'),
    __LINE__ => Sass::Value::Color.new(hue: nil, whiteness: 0.8, blackness: 0.9, alpha: 1, space: 'hwb'),
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
      result = nil

      foo = double
      allow(foo).to receive(:call) { |args|
        expect(args.length).to eq(1)
        expect(args[0].class).to eq(value.class)
        expect(args[0]).to eq(value)
        result = args[0]
        Sass::Value::Null::NULL
      }

      bar = double
      allow(bar).to receive(:call) { |args|
        expect(args.length).to eq(0)
        value
      }

      expect(
        described_class.compile_string(
          '$_: foo(bar());',
          functions: {
            'foo($arg)': ->(args) { foo.call(args) },
            'bar()': ->(args) { bar.call(args) }
          }
        ).css
      ).to eq('')

      expect(foo).to have_received(:call)
      expect(bar).to have_received(:call)

      expect(remote_eq(value, result)).to be(true)
    end
  end
end
