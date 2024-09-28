# frozen_string_literal: true

module Sass
  module Value
    # Sass's {FuzzyMath} module.
    module FuzzyMath
      PRECISION = 11

      module_function

      def equals(number1, number2)
        number1 == number2 || number1.round(PRECISION) == number2.round(PRECISION)
      end

      def less_than(number1, number2)
        number1 < number2 && !equals(number1, number2)
      end

      def less_than_or_equals(number1, number2)
        number1 < number2 || equals(number1, number2)
      end

      def greater_than(number1, number2)
        number1 > number2 && !equals(number1, number2)
      end

      def greater_than_or_equals(number1, number2)
        number1 > number2 || equals(number1, number2)
      end

      def integer?(number)
        return false unless number.finite?
        return true if number.integer?

        number.round == number.round(PRECISION)
      end

      def to_i(number)
        integer?(number) ? number.round : nil
      end

      def between(number, min, max)
        return min if equals(number, min)
        return max if equals(number, max)
        return number if number > min && number < max

        nil
      end

      def assert_between(number, min, max, name)
        result = between(number, min, max)
        return result unless result.nil?

        raise Sass::ScriptError.new("#{number} must be between #{min} and #{max}.", name)
      end

      def _clamp_like_css(number, lower_bound, upper_bound)
        number.to_f.nan? ? lower_bound : number.clamp(lower_bound, upper_bound)
      end

      def _round(number)
        number&.finite? ? number.round(PRECISION).to_f : number
      end
    end

    private_constant :FuzzyMath
  end
end
