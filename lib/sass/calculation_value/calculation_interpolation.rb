# frozen_string_literal: true

module Sass
  module CalculationValue
    # A string injected into a SassCalculation using interpolation.
    #
    # @see https://sass-lang.com/documentation/js-api/classes/calculationinterpolation/
    class CalculationInterpolation
      include CalculationValue

      # @param value [::String]
      def initialize(value)
        @value = value
      end

      # @return [::String]
      attr_reader :value

      # @return [::Boolean]
      def ==(other)
        other.is_a?(Sass::CalculationValue::CalculationInterpolation) &&
          other.value == value
      end

      # @return [Integer]
      def hash
        @hash ||= value.hash
      end
    end
  end
end
