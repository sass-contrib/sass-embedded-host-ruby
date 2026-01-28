# frozen_string_literal: true

module Sass
  module Value
    class Color
      module Space
        # @see https://github.com/sass/dart-sass/blob/main/lib/src/value/color/space/rec2020.dart
        class Rec2020
          include Space

          def bounded?
            true
          end

          def initialize
            super('rec2020', Utils::RGB_CHANNELS)
          end

          def to_linear(channel)
            (channel <=> 0) * (channel.abs**2.4)
          end

          def from_linear(channel)
            (channel <=> 0) * (channel.abs**(1 / 2.4))
          end

          private

          def transformation_matrix(dest)
            case dest
            when A98_RGB
              Conversions::LINEAR_REC2020_TO_LINEAR_A98_RGB
            when DISPLAY_P3, DISPLAY_P3_LINEAR
              Conversions::LINEAR_REC2020_TO_LINEAR_DISPLAY_P3
            when LMS
              Conversions::LINEAR_REC2020_TO_LMS
            when PROPHOTO_RGB
              Conversions::LINEAR_REC2020_TO_LINEAR_PROPHOTO_RGB
            when RGB, SRGB, SRGB_LINEAR
              Conversions::LINEAR_REC2020_TO_LINEAR_SRGB
            when XYZ_D50
              Conversions::LINEAR_REC2020_TO_XYZ_D50
            when XYZ_D65
              Conversions::LINEAR_REC2020_TO_XYZ_D65
            else
              super
            end
          end
        end

        private_constant :Rec2020

        REC2020 = Rec2020.new
      end
    end
  end
end
