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
              0.8077756760084225,
              0.32624391948277537,
              148.1202761637585
            ),
            clip: ColorConstructors.oklch(
              0.8488292928532466,
              0.3685277976813825,
              145.64495558662838
            )
          }
        ],
        [
          ColorConstructors.oklch(0.8, 2, 150),
          'srgb',
          {
            'local-minde': ColorConstructors.oklch(
              0.809152561530627,
              0.23790276994468387,
              147.40215048389234
            ),
            clip: ColorConstructors.oklch(
              0.8664396175234368,
              0.2948272245426958,
              142.4953450414439
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
