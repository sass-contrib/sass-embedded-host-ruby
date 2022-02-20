# frozen_string_literal: true

module Sass
  class Value
    # Sass's color type.
    #
    # No matter what representation was originally used to create this color, all of its channels are accessible.
    class Color < Sass::Value
      def initialize(red: nil, green: nil, blue: nil, # rubocop:disable Lint/MissingSuper
                     hue: nil, saturation: nil, lightness: nil,
                     whiteness: nil, blackness: nil,
                     alpha: nil)
        @alpha = alpha.nil? ? 1 : FuzzyMath.assert_between(alpha, 0, 1, 'alpha')
        if red && green && blue
          @red = FuzzyMath.assert_between(FuzzyMath.round(red), 0, 255, 'red')
          @green = FuzzyMath.assert_between(FuzzyMath.round(green), 0, 255, 'green')
          @blue = FuzzyMath.assert_between(FuzzyMath.round(blue), 0, 255, 'blue')
        elsif hue && saturation && lightness
          @hue = hue % 360
          @saturation = FuzzyMath.assert_between(saturation, 0, 100, 'saturation')
          @lightness = FuzzyMath.assert_between(lightness, 0, 100, 'lightness')
        elsif hue && whiteness && blackness
          @hue = hue % 360
          @whiteness = FuzzyMath.assert_between(whiteness, 0, 100, 'whiteness')
          @blackness = FuzzyMath.assert_between(blackness, 0, 100, 'blackness')
          hwb_to_rgb
          @whiteness = @blackness = nil
        else
          raise error 'Invalid Color'
        end
      end

      def change(red: nil,
                 green: nil,
                 blue: nil,
                 hue: nil,
                 saturation: nil,
                 lightness: nil,
                 whiteness: nil,
                 blackness: nil,
                 alpha: nil)
        if whiteness || blackness
          Sass::Value::Color.new(hue: hue || self.hue,
                                 whiteness: whiteness || self.whiteness,
                                 blackness: blackness || self.blackness,
                                 alpha: alpha || self.alpha)
        elsif hue || saturation || lightness
          Sass::Value::Color.new(hue: hue || self.hue,
                                 saturation: saturation || self.saturation,
                                 lightness: lightness || self.lightness,
                                 alpha: alpha || self.alpha)
        elsif red || green || blue
          Sass::Value::Color.new(red: red ? FuzzyMath.round(red) : self.red,
                                 green: green ? FuzzyMath.round(green) : self.green,
                                 blue: blue ? FuzzyMath.round(blue) : self.blue,
                                 alpha: alpha || self.alpha)
        else
          dup.instance_eval do
            @alpha = FuzzyMath.assert_between(alpha, 0, 1, 'alpha')
            self
          end
        end
      end

      def red
        hsl_to_rgb if @red.nil?

        @red
      end

      def green
        hsl_to_rgb if @green.nil?

        @green
      end

      def blue
        hsl_to_rgb if @blue.nil?

        @blue
      end

      def hue
        rgb_to_hsl if @hue.nil?

        @hue
      end

      def saturation
        rgb_to_hsl if @saturation.nil?

        @saturation
      end

      def lightness
        rgb_to_hsl if @lightness.nil?

        @lightness
      end

      def whiteness
        @whiteness ||= Rational([red, green, blue].min, 255) * 100
      end

      def blackness
        @blackness ||= 100 - (Rational([red, green, blue].max, 255) * 100)
      end

      attr_reader :alpha

      def assert_color
        self
      end

      def ==(other)
        other.is_a?(Sass::Value::Color) &&
          other.red == red &&
          other.green == green &&
          other.blue == blue &&
          other.alpha == alpha
      end

      def hash
        @hash ||= red.hash ^ green.hash ^ blue.hash ^ alpha.hash
      end

      private

      def rgb_to_hsl
        scaled_red = Rational(red, 255)
        scaled_green = Rational(green, 255)
        scaled_blue = Rational(blue, 255)

        max = [scaled_red, scaled_green, scaled_blue].max
        min = [scaled_red, scaled_green, scaled_blue].min
        delta = max - min

        if max == min
          @hue = 0
        elsif max == scaled_red
          @hue = (60 * (scaled_green - scaled_blue) / delta) % 360
        elsif max == scaled_green
          @hue = (120 + (60 * (scaled_blue - scaled_red) / delta)) % 360
        elsif max == scaled_blue
          @hue = (240 + (60 * (scaled_red - scaled_green) / delta)) % 360
        end

        lightness = @lightness = 50 * (max + min)

        @saturation = if max == min
                        0
                      elsif lightness < 50
                        100 * delta / (max + min)
                      else
                        100 * delta / (2 - max - min)
                      end
      end

      def hsl_to_rgb
        scaled_hue = Rational(hue, 360)
        scaled_saturation = Rational(saturation, 100)
        scaled_lightness = Rational(lightness, 100)

        tmp2 = if scaled_lightness <= 0.5
                 scaled_lightness * (scaled_saturation + 1)
               else
                 scaled_lightness + scaled_saturation - (scaled_lightness * scaled_saturation)
               end
        tmp1 = (scaled_lightness * 2) - tmp2
        @red = FuzzyMath.round(hsl_hue_to_rgb(tmp1, tmp2, scaled_hue + Rational(1, 3)) * 255)
        @green = FuzzyMath.round(hsl_hue_to_rgb(tmp1, tmp2, scaled_hue) * 255)
        @blue = FuzzyMath.round(hsl_hue_to_rgb(tmp1, tmp2, scaled_hue - Rational(1, 3)) * 255)
      end

      def hsl_hue_to_rgb(tmp1, tmp2, hue)
        hue += 1 if hue.negative?
        hue -= 1 if hue > 1

        if hue < Rational(1, 6)
          tmp1 + ((tmp2 - tmp1) * hue * 6)
        elsif hue < Rational(1, 2)
          tmp2
        elsif hue < Rational(2, 3)
          tmp1 + ((tmp2 - tmp1) * (Rational(2, 3) - hue) * 6)
        else
          tmp1
        end
      end

      def hwb_to_rgb
        scaled_hue = Rational(hue, 360)
        scaled_whiteness = Rational(whiteness, 100)
        scaled_blackness = Rational(blackness, 100)

        sum = scaled_whiteness + scaled_blackness
        if sum > 1
          scaled_whiteness /= sum
          scaled_blackness /= sum
        end

        factor = 1 - scaled_whiteness - scaled_blackness
        @red = hwb_hue_to_rgb(factor, scaled_whiteness, scaled_hue + Rational(1, 3))
        @green = hwb_hue_to_rgb(factor, scaled_whiteness, scaled_hue)
        @blue = hwb_hue_to_rgb(factor, scaled_whiteness, scaled_hue - Rational(1, 3))
      end

      def hwb_hue_to_rgb(factor, scaled_whiteness, scaled_hue)
        channel = (hsl_hue_to_rgb(0, 1, scaled_hue) * factor) + scaled_whiteness
        FuzzyMath.round(channel * 255)
      end
    end
  end
end
