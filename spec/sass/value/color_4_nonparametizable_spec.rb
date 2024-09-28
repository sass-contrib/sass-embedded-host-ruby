# frozen_string_literal: true

require 'spec_helper'

require_relative 'color/constructors'

describe Sass::Value::Color do
  # @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/color/color-4-nonparametizable.test.ts
  describe 'Color 4 Non-parametizable' do
    describe 'to_gamut' do
      [
        [
          ColorConstructors.oklch(0.8, 2, 150),
          'display-p3',
          {
            'local-minde': ColorConstructors.oklch(
              0.8077756841698541,
              0.3262439045095262,
              148.12027402754507
            ),
            clip: ColorConstructors.oklch(
              0.848829286984103,
              0.3685278106366152,
              145.64495037017775
            )
          }
        ],
        [
          ColorConstructors.oklch(0.8, 2, 150),
          'srgb',
          {
            'local-minde': ColorConstructors.oklch(
              0.809152570178515,
              0.23790275760347995,
              147.40214776873552
            ),
            clip: ColorConstructors.oklch(
              0.8664396115356694,
              0.2948272403370167,
              142.49533888780996
            )
          }
        ]
      ].each do |input, space, outputs|
        describe "with space #{space}" do
          outputs.each do |method, output|
            it "with method #{method}" do
              expect(input.to_gamut(space:, method: method.to_s)).to fuzzy_eq(output)
            end
          end
        end
      end
    end

    it 'channel with space specified, missing returns 0' do
      [
        [ColorConstructors.oklch(nil, nil, nil), 'lch', 'hue'],
        [ColorConstructors.oklch(nil, nil, nil), 'lch', 'lightness'],
        [ColorConstructors.oklch(nil, nil, nil), 'hsl', 'hue'],
        [ColorConstructors.oklch(nil, nil, nil), 'hsl', 'lightness'],
        [ColorConstructors.xyz(nil, nil, nil), 'lab', 'lightness']
      ].each do |color, space, channel|
        expect(color.channel(channel, space:)).to eq(0)
      end
    end
  end
end
