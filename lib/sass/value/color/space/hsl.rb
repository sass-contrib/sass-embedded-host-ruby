# frozen_string_literal: true

module Sass
  module Value
    class Color
      module Space
        # @see https://github.com/sass/dart-sass/blob/main/lib/src/value/color/space/hsl.dart
        class Hsl
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
            super('hsl', [
              Utils::HUE_CHANNEL,
              LinearChannel.new('saturation', 0, 100, requires_percent: true, lower_clamped: true).freeze,
              LinearChannel.new('lightness', 0, 100, requires_percent: true).freeze
            ].freeze)
          end

          def convert(dest, hue, saturation, lightness, alpha)
            scaled_hue = ((hue.nil? ? 0 : hue) / 360.0) % 1
            scaled_saturation = (saturation.nil? ? 0 : saturation) / 100.0
            scaled_lightness = (lightness.nil? ? 0 : lightness) / 100.0

            m2 = if scaled_lightness <= 0.5
                   scaled_lightness * (scaled_saturation + 1)
                 else
                   scaled_lightness + scaled_saturation - (scaled_lightness * scaled_saturation)
                 end
            m1 = (scaled_lightness * 2) - m2

            SRGB.convert(
              dest,
              Utils.hue_to_rgb(m1, m2, scaled_hue + (1 / 3.0)),
              Utils.hue_to_rgb(m1, m2, scaled_hue),
              Utils.hue_to_rgb(m1, m2, scaled_hue - (1 / 3.0)),
              alpha,
              missing_lightness: lightness.nil?,
              missing_chroma: saturation.nil?,
              missing_hue: hue.nil?
            )
          end
        end

        private_constant :Hsl

        HSL = Hsl.new
      end
    end
  end
end
