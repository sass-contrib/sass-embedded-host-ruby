# frozen_string_literal: true

module Sass
  module CalculationValue
    # A string injected into a SassCalculation using interpolation.
    #
    # @deprecated Use unquoted {Sass::Value::String} instead.
    # @see https://sass-lang.com/documentation/js-api/classes/calculationinterpolation/
    class CalculationInterpolation
      include CalculationValue

      class << self
        def new(value)
          Sass::Value::String.new("(#{value})", quoted: false)
        end
      end
    end
  end
end
