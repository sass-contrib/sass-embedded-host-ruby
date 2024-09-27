# frozen_string_literal: true

module Sass
  module Value
    class Color
      module Space
        # @see https://github.com/sass/dart-sass/blob/main/lib/src/value/color/space/hwb.dart
        class Hwb
          include Space

          def bounded?
            true
          end

          def legacy?
            true
          end

          def polar?
            true
          end

          def initialize
            super('hwb', [
              Utils::HUE_CHANNEL,
              LinearChannel.new('whiteness', 0, 100, requires_percent: true).freeze,
              LinearChannel.new('blackness', 0, 100, requires_percent: true).freeze
            ].freeze)
          end

          def convert(dest, hue, whiteness, blackness, alpha)
            scaled_hue = (hue.nil? ? 0 : hue) % 360 / 360.0
            scaled_whiteness = (whiteness.nil? ? 0 : whiteness) / 100.0
            scaled_blackness = (blackness.nil? ? 0 : blackness) / 100.0

            sum = scaled_whiteness + scaled_blackness
            if sum > 1
              scaled_whiteness /= sum
              scaled_blackness /= sum
            end

            factor = 1 - scaled_whiteness - scaled_blackness

            to_rgb = lambda do |hue_|
              (Utils.hue_to_rgb(0, 1, hue_) * factor) + scaled_whiteness
            end

            SRGB.convert(dest,
                         to_rgb.call(scaled_hue + (1 / 3.0)),
                         to_rgb.call(scaled_hue),
                         to_rgb.call(scaled_hue - (1 / 3.0)),
                         alpha,
                         missing_hue: hue.nil?)
          end
        end

        private_constant :Hwb

        HWB = Hwb.new
      end
    end
  end
end
