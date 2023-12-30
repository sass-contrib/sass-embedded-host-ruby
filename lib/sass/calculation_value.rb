# frozen_string_literal: true

module Sass
  # The type of values that can be arguments to a SassCalculation.
  #
  # @see https://sass-lang.com/documentation/js-api/types/calculationvalue/
  module CalculationValue
    private

    def assert_calculation_value(value)
      raise Sass::ScriptError, "#{value} is not a calculation value" unless value.is_a?(Sass::CalculationValue)

      raise Sass::ScriptError, "Expected #{value} to be unquoted" if value.is_a?(Sass::Value::String) && value.quoted?
    end
  end
end

require_relative 'calculation_value/calculation_operation'
