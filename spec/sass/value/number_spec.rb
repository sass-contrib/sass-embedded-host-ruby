# frozen_string_literal: true

require 'spec_helper'

describe Sass::Value::Number do
  precision = 10

  describe 'unitless' do
    describe 'integer' do
      number = nil
      before do
        number = described_class.new(123)
      end

      describe 'construction' do
        it 'is a value' do
          expect(number).to be_a(Sass::Value)
        end

        it 'is a number' do
          expect(number).to be_a(described_class)
          expect { number.assert_number }.not_to raise_error
        end

        it 'has no units' do
          expect(number.numerator_units).to be_empty
          expect(number.denominator_units).to be_empty
          expect(number.units?).to be(false)
          expect(number.unit?('px')).to be(false)
          expect { number.assert_unitless }.not_to raise_error
          expect { number.assert_unit('px') }.to raise_error(Sass::ScriptError)
        end

        it "isn't any other type" do
          expect { number.assert_boolean }.to raise_error(Sass::ScriptError)
          expect { number.assert_color }.to raise_error(Sass::ScriptError)
          expect { number.assert_function }.to raise_error(Sass::ScriptError)
          expect { number.assert_map }.to raise_error(Sass::ScriptError)
          expect(number.to_map).to be_nil
          expect { number.assert_string }.to raise_error(Sass::ScriptError)
        end
      end

      describe 'value' do
        it 'has the correct value' do
          expect(number.value).to eq(123)
        end

        it 'is an int' do
          expect(number.integer?).to be(true)
          expect(number.to_i).to eq(123)
          expect(number.assert_integer).to eq(123)
        end

        it 'clamps within the given range' do
          expect(number.assert_between(0, 123)).to eq(123)
          expect(number.assert_between(123, 123)).to eq(123)
          expect(number.assert_between(123, 1000)).to eq(123)
        end

        it 'rejects a value outside the range' do
          expect { number.assert_between(0, 122) }.to raise_error(Sass::ScriptError)
          expect { number.assert_between(124, 1000) }.to raise_error(Sass::ScriptError)
        end
      end

      describe 'equality' do
        it 'equals the same number' do
          expect(number).to eq(described_class.new(123))
        end

        it 'equals the same number within precision tolerance' do
          expect(number).to eq(described_class.new(123 + 10.pow(-precision - 2)))
          expect(number).to eq(described_class.new(123 - 10.pow(-precision - 2)))
        end

        it "doesn't equal a different number" do
          expect(number).not_to eq(described_class.new(122))
          expect(number).not_to eq(described_class.new(124))
          expect(number).not_to eq(described_class.new(123 + 10.pow(-precision - 1)))
          expect(number).not_to eq(described_class.new(123 - 10.pow(-precision - 1)))
        end

        it "doesn't equal a number with units" do
          expect(number).not_to eq(described_class.new(123, 'px'))
        end
      end

      it 'is not compatible with a unit' do
        expect(number.compatible_with_unit?('px')).to be(false)
        expect(number.compatible_with_unit?('abc')).to be(false)
      end

      describe 'convert' do
        it 'can be converted to unitless' do
          expect(number.convert([], [])).to eq(described_class.new(123))
        end

        it 'can be converted to match unitless' do
          expect(number.convert_to_match(described_class.new(456))).to eq(described_class.new(123))
        end

        it 'cannot be converted to a unit' do
          expect { number.convert(['px'], []) }.to raise_error(Sass::ScriptError)
        end

        it 'cannot be converted to match a unit' do
          expect { number.convert_to_match(described_class.new(456, 'px')) }.to raise_error(Sass::ScriptError)
        end

        it 'can convert its value to unitless' do
          expect(number.convert_value([], [])).to eq(123)
        end

        it 'can convert its value to match unitless' do
          expect(number.convert_value_to_match(described_class.new(456))).to eq(123)
        end

        it 'cannot convert its value to a unit' do
          expect { number.convert_value(['px'], []) }.to raise_error(Sass::ScriptError)
        end

        it 'cannot convert its value to match a unit' do
          expect do
            number.convert_value_to_match(described_class.new(456, 'px'))
          end.to raise_error(Sass::ScriptError)
        end
      end

      describe 'coerce' do
        it 'can be coerced to unitless' do
          expect(number.coerce([], [])).to eq(described_class.new(123))
        end

        it 'can be coerced to match unitless' do
          expect(number.coerce_to_match(described_class.new(456))).to eq(described_class.new(123))
        end

        it 'can be coerced to a unit' do
          expect(number.coerce(['px'], [])).to eq(described_class.new(123, { numerator_units: ['px'] }))
        end

        it 'can be coerced to match a unit' do
          expect(number.coerce_to_match(described_class.new(456, { numerator_units: ['px'] })))
            .to eq(described_class.new(123, { numerator_units: ['px'] }))
        end

        it 'can coerce its value to unitless' do
          expect(number.coerce_value([], [])).to eq(123)
        end

        it 'can coerce its value to match unitless' do
          expect(number.coerce_value_to_match(described_class.new(456))).to eq(123)
        end

        it 'can coerce its value to a unit' do
          expect(number.coerce_value(['px'], [])).to eq(123)
        end

        it 'can coerce its value to match a unit' do
          expect(number.coerce_value_to_match(described_class.new(456, { numerator_units: ['px'] }))).to eq(123)
        end
      end
    end

    describe 'fuzzy integer' do
      number = nil
      before do
        number = described_class.new(123.000000000001)
      end

      it 'has the correct value' do
        expect(number.value).to eq(123.000000000001)
      end

      it 'is an int' do
        expect(number.integer?).to be(true)
        expect(number.to_i).to eq(123)
        expect(number.assert_integer).to eq(123)
      end

      it 'clamps within the given range' do
        expect(number.assert_between(0, 123)).to eq(123)
        expect(number.assert_between(123, 123)).to eq(123)
        expect(number.assert_between(123, 1000)).to eq(123)
      end

      it 'rejects a value outside the range' do
        expect { number.assert_between(0, 122) }.to raise_error(Sass::ScriptError)
        expect { number.assert_between(124, 1000) }.to raise_error(Sass::ScriptError)
      end

      it 'equals the same number' do
        expect(number).to eq(described_class.new(123 + 10.pow(-precision - 2)))
      end

      it 'equals the same number within precision tolerance' do
        expect(number).to eq(described_class.new(123))
        expect(number).to eq(described_class.new(123 - 10.pow(-precision - 2)))
      end
    end

    describe 'double' do
      number = nil
      before do
        number = described_class.new(123.456)
      end

      it 'has the correct value' do
        expect(number.value).to eq(123.456)
      end

      it 'is not an int' do
        expect(number.integer?).to be(false)
        expect(number.to_i).to be_nil
        expect { number.assert_integer }.to raise_error(Sass::ScriptError)
      end
    end
  end

  describe 'single numerator unit' do
    number = nil
    before do
      number = described_class.new(123, 'px')
    end

    describe 'construction' do
      it 'has that unit' do
        expect(number.numerator_units).to eq(['px'])
        expect(number.units?).to be(true)
        expect(number.unit?('px')).to be(true)
        expect { number.assert_unit('px') }.not_to raise_error
        expect { number.assert_unitless }.to raise_error(Sass::ScriptError)
      end

      it 'has no other units' do
        expect(number.denominator_units).to be_empty
        expect(number.unit?('in')).to be(false)
        expect { number.assert_unit('in') }.to raise_error(Sass::ScriptError)
      end
    end

    describe 'compatibility' do
      it 'is compatible with the same unit' do
        expect(number.compatible_with_unit?('px')).to be(true)
      end

      it 'is compatible with a compatible unit' do
        expect(number.compatible_with_unit?('in')).to be(true)
      end

      it 'is incompatible with an incompatible unit' do
        expect(number.compatible_with_unit?('abc')).to be(false)
      end
    end

    describe 'convert' do
      it 'cannot be converted to unitless' do
        expect { number.convert([], []) }.to raise_error(Sass::ScriptError)
      end

      it 'cannot be converted to match unitless' do
        expect { number.convert_to_match(described_class.new(456)) }.to raise_error(Sass::ScriptError)
      end

      it 'can be converted to compatible units' do
        expect(number.convert(['px'], [])).to eq(number)
        expect(number.convert(['in'], [])).to eq(described_class.new(1.28125, 'in'))
      end

      it 'can be converted to match compatible units' do
        expect(number.convert_to_match(described_class.new(456, 'px'))).to eq(number)
        expect(number.convert_to_match(described_class.new(456, 'in')))
          .to eq(described_class.new(1.28125, 'in'))
      end

      it 'cannot be converted to incompatible units' do
        expect { number.convert(['abc'], []) }.to raise_error(Sass::ScriptError)
      end

      it 'cannot be converted to match incompatible units' do
        expect { number.convert_to_match(described_class.new(456, 'abc')) }.to raise_error(Sass::ScriptError)
      end

      it 'cannot convert its value to unitless' do
        expect { number.convert_value([], []) }.to raise_error(Sass::ScriptError)
      end

      it 'cannot convert its value to match unitless' do
        expect { number.convert_value_to_match(described_class.new(456)) }.to raise_error(Sass::ScriptError)
      end

      it 'can convert its value to compatible units' do
        expect(number.convert_value(['px'], [])).to eq(123)
        expect(number.convert_value(['in'], [])).to eq(1.28125)
      end

      it 'can convert its value to match compatible units' do
        expect(number.convert_value_to_match(described_class.new(456, 'px'))).to eq(123)
        expect(number.convert_value_to_match(described_class.new(456, 'in'))).to eq(1.28125)
      end

      it 'cannot convert its value to incompatible units' do
        expect { number.convert_value(['abc'], []) }.to raise_error(Sass::ScriptError)
      end

      it 'cannot convert its value to match incompatible units' do
        expect { number.convert_value_to_match(described_class.new(456, 'abc')) }.to raise_error(Sass::ScriptError)
      end
    end

    describe 'coerce' do
      it 'can be coerced to unitless' do
        expect(number.coerce([], [])).to eq(described_class.new(123))
      end

      it 'can be coerced to match unitless' do
        expect(number.coerce_to_match(described_class.new(456))).to eq(described_class.new(123))
      end

      it 'can be coerced to compatible units' do
        expect(number.coerce(['px'], [])).to eq(number)
        expect(number.coerce(['in'], [])).to eq(described_class.new(1.28125, 'in'))
      end

      it 'can be coerced to match compatible units' do
        expect(number.coerce_to_match(described_class.new(456, 'px'))).to eq(number)
        expect(number.coerce_to_match(described_class.new(456, 'in')))
          .to eq(described_class.new(1.28125, 'in'))
      end

      it 'cannot be coerced to incompatible units' do
        expect { number.coerce(['abc'], []) }.to raise_error(Sass::ScriptError)
      end

      it 'cannot be coerced to match incompatible units' do
        expect { number.coerce_to_match(described_class.new(456, 'abc')) }.to raise_error(Sass::ScriptError)
      end

      it 'can coerce its value to unitless' do
        expect(number.coerce_value([], [])).to eq(123)
      end

      it 'can coerce its value to match unitless' do
        expect(number.coerce_value_to_match(described_class.new(456))).to eq(123)
      end

      it 'can coerce its value to compatible units' do
        expect(number.coerce_value(['px'], [])).to eq(123)
        expect(number.coerce_value(['in'], [])).to eq(1.28125)
      end

      it 'can coerce its value to match compatible units' do
        expect(number.coerce_value_to_match(described_class.new(456, 'px'))).to eq(123)
        expect(number.coerce_value_to_match(described_class.new(456, 'in'))).to eq(1.28125)
      end

      it 'cannot coerce its value to incompatible units' do
        expect { number.coerce_value(['abc'], []) }.to raise_error(Sass::ScriptError)
      end

      it 'cannot coerce its value to match incompatible units' do
        expect { number.coerce_value_to_match(described_class.new(456, 'abc')) }.to raise_error(Sass::ScriptError)
      end
    end

    describe 'equality' do
      it 'equals the same number' do
        expect(number).to eq(described_class.new(123, 'px'))
      end

      it 'equals an equivalent number' do
        expect(number).to eq(described_class.new(1.28125, 'in'))
      end

      it "doesn't equal a unitless number" do
        expect(number).not_to eq(described_class.new(123))
      end

      it "doesn't equal a number with different units" do
        expect(number).not_to eq(described_class.new(123, 'abc'))
        expect(number).not_to eq(described_class.new(123, { numerator_units: %w[px px] }))
        expect(number).not_to eq(described_class.new(123, { numerator_units: ['px'], denominator_units: ['abc'] }))
        expect(number).not_to eq(described_class.new(123, { denominator_units: ['px'] }))
      end
    end
  end

  describe 'numerator and denominator units' do
    number = nil
    before do
      number = described_class.new(123, { numerator_units: ['px'], denominator_units: ['ms'] })
    end

    describe 'construction' do
      it 'has those units' do
        expect(number.units?).to be(true)
        expect(number.unit?('px')).to be(false)
        expect { number.assert_unit('px') }.to raise_error(Sass::ScriptError)
        expect { number.assert_unitless }.to raise_error(Sass::ScriptError)
      end

      it 'does not simplify incompatible units' do
        expect(number.numerator_units).to eq(['px'])
        expect(number.denominator_units).to eq(['ms'])
      end

      it 'simplifies compatible units' do
        number = described_class.new(123, { numerator_units: %w[px s], denominator_units: ['ms'] })
        expect(number.value).to eq(123_000)
        expect(number.numerator_units).to eq(['px'])
        expect(number.denominator_units).to be_empty
      end

      it 'does not simplify unknown units' do
        number = described_class.new(123, { numerator_units: ['abc'], denominator_units: ['def'] })
        expect(number.value).to eq(123)
        expect(number.numerator_units).to eq(['abc'])
        expect(number.denominator_units).to eq(['def'])
      end
    end

    describe 'compatibility' do
      it 'is incompatible with the numerator unit' do
        expect(number.compatible_with_unit?('px')).to be(false)
      end

      it 'is incompatible with the denominator unit' do
        expect(number.compatible_with_unit?('ms')).to be(false)
      end
    end

    describe 'convert' do
      it 'cannot be converted to unitless' do
        expect { number.convert([], []) }.to raise_error(Sass::ScriptError)
      end

      it 'cannot be converted to match unitless' do
        expect { number.convert_to_match(described_class.new(456)) }.to raise_error(Sass::ScriptError)
      end

      it 'can be converted to compatible units' do
        expect(number.convert(['px'], ['ms'])).to eq(number)
        expect(number.convert(['in'], ['s'])).to eq(described_class.new(1281.25, {
                                                                          numerator_units: ['in'],
                                                                          denominator_units: ['s']
                                                                        }))
      end

      it 'can be converted to match compatible units' do
        expect(number.convert_to_match(described_class.new(456, {
                                                             numerator_units: ['px'],
                                                             denominator_units: ['ms']
                                                           })))
          .to eq(number)
        expect(number.convert_to_match(described_class.new(456, {
                                                             numerator_units: ['in'],
                                                             denominator_units: ['s']
                                                           })))
          .to eq(described_class.new(1281.25, {
                                       numerator_units: ['in'],
                                       denominator_units: ['s']
                                     }))
      end

      it 'cannot be converted to incompatible units' do
        expect { number.convert(['abc'], []) }.to raise_error(Sass::ScriptError)
      end

      it 'cannot be converted to match incompatible units' do
        expect { number.convert_to_match(described_class.new(456, 'abc')) }.to raise_error(Sass::ScriptError)
      end

      it 'cannot convert its value to unitless' do
        expect { number.convert_value([], []) }.to raise_error(Sass::ScriptError)
      end

      it 'cannot convert its value to match unitless' do
        expect { number.convert_value_to_match(described_class.new(456)) }.to raise_error(Sass::ScriptError)
      end

      it 'can convert its value to compatible units' do
        expect(number.convert_value(['px'], ['ms'])).to eq(123)
        expect(number.convert_value(['in'], ['s'])).to eq(1281.25)
      end

      it 'can convert its value to match compatible units' do
        expect(number.convert_value_to_match(described_class.new(456, {
                                                                   numerator_units: ['px'],
                                                                   denominator_units: ['ms']
                                                                 }))).to eq(123)
        expect(number.convert_value_to_match(described_class.new(456, {
                                                                   numerator_units: ['in'],
                                                                   denominator_units: ['s']
                                                                 }))).to eq(1281.25)
      end

      it 'cannot convert its value to incompatible units' do
        expect { number.convert_value(['abc'], []) }.to raise_error(Sass::ScriptError)
      end

      it 'cannot convert its value to match incompatible units' do
        expect { number.convert_value_to_match(described_class.new(456, 'abc')) }.to raise_error(Sass::ScriptError)
      end
    end

    describe 'coerce' do
      it 'can be coerced to unitless' do
        expect(number.coerce([], [])).to eq(described_class.new(123))
      end

      it 'can be coerced to match unitless' do
        expect(number.coerce_to_match(described_class.new(456))).to eq(described_class.new(123))
      end

      it 'can be coerced to compatible units' do
        expect(number.coerce(['px'], ['ms'])).to eq(number)
        expect(number.coerce(['in'], ['s'])).to eq(described_class.new(1281.25, {
                                                                         numerator_units: ['in'],
                                                                         denominator_units: ['s']
                                                                       }))
      end

      it 'can be coerced to match compatible units' do
        expect(number.coerce_to_match(described_class.new(456, {
                                                            numerator_units: ['px'],
                                                            denominator_units: ['ms']
                                                          }))).to eq(number)
        expect(number.coerce_to_match(described_class.new(456, {
                                                            numerator_units: ['in'],
                                                            denominator_units: ['s']
                                                          }))).to eq(described_class.new(1281.25, {
                                                                                           numerator_units: ['in'],
                                                                                           denominator_units: ['s']
                                                                                         }))
      end

      it 'cannot be coerced to incompatible units' do
        expect { number.coerce(['abc'], []) }.to raise_error(Sass::ScriptError)
      end

      it 'cannot be coerced to match incompatible units' do
        expect do
          number.coerce_to_match(described_class.new(456, {
                                                       numerator_units: ['abc'],
                                                       denominator_units: []
                                                     }))
        end.to raise_error(Sass::ScriptError)
      end

      it 'can coerce its value to unitless' do
        expect(number.coerce_value([], [])).to eq(123)
      end

      it 'can coerce its value to match unitless' do
        expect(number.coerce_value_to_match(described_class.new(456, {
                                                                  numerator_units: [],
                                                                  denominator_units: []
                                                                }))).to eq(123)
      end

      it 'can coerce its value to compatible units' do
        expect(number.coerce_value(['px'], ['ms'])).to eq(123)
        expect(number.coerce_value(['in'], ['s'])).to eq(1281.25)
      end

      it 'can coerce its value to match compatible units' do
        expect(number.coerce_value_to_match(described_class.new(456, {
                                                                  numerator_units: ['px'],
                                                                  denominator_units: ['ms']
                                                                }))).to eq(123)
        expect(number.coerce_value_to_match(described_class.new(456, {
                                                                  numerator_units: ['in'],
                                                                  denominator_units: ['s']
                                                                }))).to eq(1281.25)
      end

      it 'cannot coerce its value to incompatible units' do
        expect { number.coerce_value(['abc'], []) }.to raise_error(Sass::ScriptError)
      end

      it 'cannot coerce its value to match incompatible units' do
        expect do
          number.coerce_value_to_match(described_class.new(456, {
                                                             numerator_units: ['abc'],
                                                             denominator_units: []
                                                           }))
        end.to raise_error(Sass::ScriptError)
      end
    end

    describe 'equality' do
      it 'equals the same number' do
        expect(number).to eq(described_class.new(123, {
                                                   numerator_units: ['px'],
                                                   denominator_units: ['ms']
                                                 }))
      end

      it 'equals an equivalent number' do
        expect(number).to eq(described_class.new(1281.25, {
                                                   numerator_units: ['in'],
                                                   denominator_units: ['s']
                                                 }))
      end

      it "doesn't equal a unitless number" do
        expect(number).not_to eq(described_class.new(24.6))
      end

      it "doesn't equal a number with different units" do
        expect(number).not_to eq(described_class.new(123, 'px'))
        expect(number).not_to eq(described_class.new(123, { denominator_units: ['ms'] }))
        expect(number).not_to eq(described_class.new(123, {
                                                       numerator_units: ['ms'],
                                                       denominator_units: ['px']
                                                     }))
        expect(number).not_to eq(described_class.new(123, {
                                                       numerator_units: ['in'],
                                                       denominator_units: ['s']
                                                     }))
      end
    end
  end
end
