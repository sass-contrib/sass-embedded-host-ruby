# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/calculation.test.ts
describe Sass::Value::Calculation do
  let(:valid_calculation_values) do
    [
      Sass::Value::Number.new(1),
      Sass::Value::String.new('1', quoted: false),
      described_class.calc(Sass::Value::Number.new(1)),
      Sass::CalculationValue::CalculationOperation.new('+', Sass::Value::Number.new(1), Sass::Value::Number.new(1))
    ]
  end

  let(:invalid_calculation_values) do
    [Sass::Value::String.new('1', quoted: true)]
  end

  describe 'construction' do
    subject(:calculation) do
      described_class.calc(Sass::Value::Number.new(1))
    end

    it 'is a value' do
      expect(calculation).to be_a(Sass::Value)
    end

    it 'is a calculation' do
      expect(calculation).to be_a(described_class)
      expect(calculation.assert_calculation).to be(calculation)
    end

    it "isn't any other type" do
      expect { calculation.assert_boolean }.to raise_error(Sass::ScriptError)
      expect { calculation.assert_color }.to raise_error(Sass::ScriptError)
      expect { calculation.assert_function }.to raise_error(Sass::ScriptError)
      expect { calculation.assert_map }.to raise_error(Sass::ScriptError)
      expect(calculation.to_map).to be_nil
      expect { calculation.assert_mixin }.to raise_error(Sass::ScriptError)
      expect { calculation.assert_number }.to raise_error(Sass::ScriptError)
      expect { calculation.assert_string }.to raise_error(Sass::ScriptError)
    end
  end

  describe 'calc' do
    it 'correctly stores name and arguments' do
      result = described_class.calc(Sass::Value::Number.new(1))
      expect(result.name).to be('calc')
      expect(result.arguments).to eq([Sass::Value::Number.new(1)])
    end

    it 'rejects invalid arguments' do
      invalid_calculation_values.each do |value|
        expect { described_class.calc(value) }.to raise_error(Sass::ScriptError)
      end
    end

    it 'accepts valid arguments' do
      valid_calculation_values.each do |value|
        expect { described_class.calc(value) }.not_to raise_error
      end
    end
  end

  describe 'min' do
    it 'correctly stores name and arguments' do
      result = described_class.min([
                                     Sass::Value::Number.new(1),
                                     Sass::Value::Number.new(2)
                                   ])
      expect(result.name).to be('min')
      expect(result.arguments).to eq([
                                       Sass::Value::Number.new(1),
                                       Sass::Value::Number.new(2)
                                     ])
    end

    it 'rejects invalid arguments' do
      invalid_calculation_values.each do |value|
        expect { described_class.min([value, Sass::Value::Number.new(2)]) }.to raise_error(Sass::ScriptError)
        expect { described_class.min([Sass::Value::Number.new(1), value]) }.to raise_error(Sass::ScriptError)
      end
    end

    it 'accepts valid arguments' do
      valid_calculation_values.each do |value|
        expect { described_class.min([value, Sass::Value::Number.new(2)]) }.not_to raise_error
        expect { described_class.min([Sass::Value::Number.new(1), value]) }.not_to raise_error
      end
    end
  end

  describe 'max' do
    it 'correctly stores name and arguments' do
      result = described_class.max([
                                     Sass::Value::Number.new(1),
                                     Sass::Value::Number.new(2)
                                   ])
      expect(result.name).to be('max')
      expect(result.arguments).to eq([
                                       Sass::Value::Number.new(1),
                                       Sass::Value::Number.new(2)
                                     ])
    end

    it 'rejects invalid arguments' do
      invalid_calculation_values.each do |value|
        expect { described_class.max([value, Sass::Value::Number.new(2)]) }.to raise_error(Sass::ScriptError)
        expect { described_class.max([Sass::Value::Number.new(1), value]) }.to raise_error(Sass::ScriptError)
      end
    end

    it 'accepts valid arguments' do
      valid_calculation_values.each do |value|
        expect { described_class.max([value, Sass::Value::Number.new(2)]) }.not_to raise_error
        expect { described_class.max([Sass::Value::Number.new(1), value]) }.not_to raise_error
      end
    end
  end

  describe 'clamp' do
    it 'correctly stores name and arguments' do
      result = described_class.clamp(
        Sass::Value::Number.new(1),
        Sass::Value::Number.new(2),
        Sass::Value::Number.new(3)
      )
      expect(result.name).to be('clamp')
      expect(result.arguments).to eq([
                                       Sass::Value::Number.new(1),
                                       Sass::Value::Number.new(2),
                                       Sass::Value::Number.new(3)
                                     ])
    end

    it 'rejects invalid arguments' do
      invalid_calculation_values.each do |value|
        expect do
          described_class.clamp(value, Sass::Value::Number.new(2),
                                Sass::Value::Number.new(3))
        end.to raise_error(Sass::ScriptError)
        expect do
          described_class.clamp(Sass::Value::Number.new(1), value,
                                Sass::Value::Number.new(3))
        end.to raise_error(Sass::ScriptError)
        expect do
          described_class.clamp(Sass::Value::Number.new(1), Sass::Value::Number.new(2),
                                value)
        end.to raise_error(Sass::ScriptError)
      end
    end

    it 'accepts valid arguments' do
      valid_calculation_values.each do |value|
        expect do
          described_class.clamp(value, Sass::Value::Number.new(2), Sass::Value::Number.new(3))
        end.not_to raise_error
        expect do
          described_class.clamp(Sass::Value::Number.new(1), value, Sass::Value::Number.new(3))
        end.not_to raise_error
        expect do
          described_class.clamp(Sass::Value::Number.new(1), Sass::Value::Number.new(2), value)
        end.not_to raise_error
      end
    end

    # When `clamp()` is called with less than three arguments, the list of
    # accepted values is much narrower
    valid_clamp_values = [
      Sass::Value::String.new('1', quoted: false)
    ]
    invalid_clamp_values = [
      Sass::Value::Number.new(1),
      Sass::Value::String.new('1', quoted: true)
    ]

    it 'rejects invalid values for one argument' do
      invalid_clamp_values.each do |value|
        expect { described_class.clamp(value) }.to raise_error(Sass::ScriptError)
      end
    end

    it 'accepts valid values for one argument' do
      valid_clamp_values.each do |value|
        expect { described_class.clamp(value) }.not_to raise_error
      end
    end

    it 'rejects invalid values for two arguments' do
      invalid_clamp_values.each do |value|
        expect { described_class.clamp(value, value) }.to raise_error(Sass::ScriptError)
      end
    end

    it 'accepts valid values for two arguments' do
      valid_clamp_values.each do |value|
        expect { described_class.clamp(value, value) }.not_to raise_error
      end
    end
  end

  describe 'simplifies' do
    it 'calc()' do
      fn = lambda do |_args|
        described_class.calc(
          Sass::CalculationValue::CalculationOperation.new('+', Sass::Value::Number.new(1), Sass::Value::Number.new(2))
        )
      end

      expect(
        Sass.compile_string('a {b: foo()}',
                            functions: { 'foo()': fn }).css
      ).to eq("a {\n  b: 3;\n}")
    end

    it 'clamp()' do
      fn = lambda do |_args|
        described_class.clamp(
          Sass::Value::Number.new(1),
          Sass::Value::Number.new(2),
          Sass::Value::Number.new(3)
        )
      end

      expect(
        Sass.compile_string('a {b: foo()}',
                            functions: { 'foo()': fn }).css
      ).to eq("a {\n  b: 2;\n}")
    end

    it 'min()' do
      fn = lambda do |_args|
        described_class.min([Sass::Value::Number.new(1), Sass::Value::Number.new(2)])
      end

      expect(
        Sass.compile_string('a {b: foo()}',
                            functions: { 'foo()': fn }).css
      ).to eq("a {\n  b: 1;\n}")
    end

    it 'max()' do
      fn = lambda do |_args|
        described_class.max([Sass::Value::Number.new(1), Sass::Value::Number.new(2)])
      end

      expect(
        Sass.compile_string('a {b: foo()}',
                            functions: { 'foo()': fn }).css
      ).to eq("a {\n  b: 2;\n}")
    end

    it 'operations' do
      fn = lambda do |_args|
        described_class.calc(
          Sass::CalculationValue::CalculationOperation.new(
            '+',
            described_class.min([Sass::Value::Number.new(3), Sass::Value::Number.new(4)]),
            Sass::CalculationValue::CalculationOperation.new(
              '*',
              described_class.max([Sass::Value::Number.new(5), Sass::Value::Number.new(6)]),
              Sass::CalculationValue::CalculationOperation.new(
                '-',
                Sass::Value::Number.new(3),
                Sass::CalculationValue::CalculationOperation.new(
                  '/',
                  Sass::Value::Number.new(4),
                  Sass::Value::Number.new(5)
                )
              )
            )
          )
        )
      end

      expect(
        Sass.compile_string('a {b: foo()}',
                            functions: { 'foo()': fn }).css
      ).to eq("a {\n  b: 16.2;\n}")
    end
  end

  describe 'throws when simplifying' do
    it 'calc() with more than one argument' do
      fn = lambda do |_args|
        described_class.calc(Sass::Value::Number.new(1), Sass::Value::Number.new(2))
      end

      expect do
        Sass.compile_string('a {b: foo()}',
                            functions: { 'foo()': fn }).css
      end.to raise_sass_compile_error
    end

    it 'clamp() with the wrong argument' do
      fn = lambda do |_args|
        described_class.clamp(Sass::Value::Number.new('1'))
      end

      expect do
        Sass.compile_string('a {b: foo()}',
                            functions: { 'foo()': fn }).css
      end.to raise_sass_compile_error.with_message('SassString')
    end

    it 'an unknown calculation function' do
      fn = lambda do |_args|
        described_class.send(:new, 'foo', [Sass::Value::Number.new(1)])
      end

      expect do
        Sass.compile_string('a {b: foo()}',
                            functions: { 'foo()': fn }).css
      end.to raise_error(/"foo" is not a recognized calculation type/)
    end
  end

  describe 'CalculationOperation' do
    let(:valid_operators) do
      ['+', '-', '*', '/']
    end

    let(:invalid_operators) do
      ['||', '&&', 'plus', 'minus', '']
    end

    describe 'construction' do
      it 'rejects invalid operators' do
        invalid_operators.each do |operator|
          expect do
            Sass::CalculationValue::CalculationOperation.new(
              operator,
              Sass::Value::Number.new(1),
              Sass::Value::Number.new(2)
            )
          end.to raise_error(Sass::ScriptError)
        end
      end

      it 'accepts valid operators' do
        valid_operators.each do |operator|
          expect do
            Sass::CalculationValue::CalculationOperation.new(
              operator,
              Sass::Value::Number.new(1),
              Sass::Value::Number.new(2)
            )
          end.not_to raise_error
        end
      end
    end

    it 'rejects invalid operands' do
      invalid_calculation_values.each do |operand|
        expect do
          Sass::CalculationValue::CalculationOperation.new('+', operand, Sass::Value::Number.new(1))
        end.to raise_error(Sass::ScriptError)
        expect do
          Sass::CalculationValue::CalculationOperation.new('+', Sass::Value::Number.new(1), operand)
        end.to raise_error(Sass::ScriptError)
      end
    end

    it 'accepts valid operands' do
      valid_calculation_values.each do |operand|
        expect do
          Sass::CalculationValue::CalculationOperation.new('+', operand, Sass::Value::Number.new(1))
        end.not_to raise_error
        expect do
          Sass::CalculationValue::CalculationOperation.new('+', Sass::Value::Number.new(1), operand)
        end.not_to raise_error
      end
    end

    describe 'stores' do
      subject(:operation) do
        Sass::CalculationValue::CalculationOperation.new(
          '+',
          Sass::Value::Number.new(1),
          Sass::Value::Number.new(2)
        )
      end

      it 'operator' do
        expect(operation.operator).to eq('+')
      end

      it 'left' do
        expect(operation.left).to eq(Sass::Value::Number.new(1))
      end

      it 'right' do
        expect(operation.right).to eq(Sass::Value::Number.new(2))
      end
    end
  end
end
