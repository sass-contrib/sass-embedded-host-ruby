# frozen_string_literal: true

require 'spec_helper'

require_relative 'color/spaces'
require_relative 'color/utils'

describe Sass::Value::Color do
  # @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/color/color-4-channels.test.ts
  describe 'Color 4 Channels' do
    COLOR_SPACES.each_value do |space|
      describe space.name do
        subject(:color) do
          space.constructor(*space.pink)
        end

        describe 'channels_or_nil' do
          it 'returns an array' do
            expect(color.channels_or_nil).to fuzzy_match_array(space.pink)
          end

          it 'returns channel value or nil, excluding alpha' do
            pink_cases = ColorUtils.channel_cases(*space.pink)
            pink_cases.each do |channels|
              color = space.constructor(*channels)
              expect(color.channels_or_nil).to fuzzy_match_array(channels.first(3))
            end
          end
        end

        describe 'channels' do
          it 'returns an array' do
            expect(color.channels).to fuzzy_match_array(space.pink)
          end

          it 'returns channel value or nil, excluding alpha' do
            pink_cases = ColorUtils.channel_cases(*space.pink)
            pink_cases.each do |channels|
              expected = channels.first(3).map do |channel|
                channel || 0
              end
              color = space.constructor(*channels)
              expect(color.channels).to fuzzy_match_array(expected)
            end
          end

          it 'channel_missing?' do
            pink_cases = ColorUtils.channel_cases(*space.pink)
            pink_cases.each do |channels|
              expected = channels.map(&:nil?)
              expected << false if expected.length == 3
              color = space.constructor(*channels)
              expect(color.channel_missing?(space.channels[0])).to be(expected[0])
              expect(color.channel_missing?(space.channels[1])).to be(expected[1])
              expect(color.channel_missing?(space.channels[2])).to be(expected[2])
              expect(color.channel_missing?('alpha')).to be(expected[3])
            end
          end
        end

        describe 'channel' do
          describe 'without space specified' do
            it 'throws an error if channel not in space' do
              channels_not_in_space = ColorUtils::CHANNEL_NAMES.dup
              space.channels.each do |channel|
                channels_not_in_space.delete(channel)
              end
              channels_not_in_space.each do |channel|
                expect { color.channel(channel) }.to raise_error(Sass::ScriptError)
              end
            end

            it 'returns value if no space specified' do
              space.channels.each_with_index do |channel, index|
                expect(color.channel(channel)).to fuzzy_eq(space.pink[index])
              end
              expect(color.channel('alpha')).to eq(1)
            end

            it 'returns 0 for missing channels' do
              nil_color = space.constructor(nil, nil, nil, nil)
              space.channels.each do |channel|
                expect(nil_color.channel(channel)).to eq(0)
              end
              expect(nil_color.channel('alpha')).to eq(0)
            end
          end

          describe 'with space specified' do
            COLOR_SPACES.each_value do |destination_space|
              it "throws an error if channel not in #{destination_space.name}" do
                channels_not_in_space = ColorUtils::CHANNEL_NAMES.dup
                destination_space.channels.each do |channel|
                  channels_not_in_space.delete(channel)
                end
                channels_not_in_space.each do |channel|
                  expect do
                    color.channel(channel, space: destination_space.name)
                  end.to raise_error(Sass::ScriptError)
                end
              end

              it "returns value when #{destination_space.name} is specified" do
                destination_space.channels.each_with_index do |channel, index|
                  expect(color.channel(channel,
                                       space: destination_space.name)).to fuzzy_eq(destination_space.pink[index])
                end
                expect(color.channel('alpha', space: destination_space.name)).to eq(1)
              end
            end
          end
        end

        describe 'alpha' do
          it 'returns value if set' do
            expect(space.constructor(*space.pink, 0).alpha).to eq(0)
            expect(space.constructor(*space.pink, 1).alpha).to eq(1)
            expect(space.constructor(*space.pink, 0.5).alpha).to eq(0.5)
          end

          it 'returns 1 if not set' do
            no_alpha_color = space.constructor(0, 0, 0)
            expect(no_alpha_color.alpha).to eq(1)
          end

          it 'returns 0 if missing' do
            no_alpha_color = space.constructor(0, 0, 0, nil)
            expect(no_alpha_color.alpha).to eq(0)
          end
        end
      end

      next if %w[hsl hwb lch oklch].include?(space.name)

      describe 'channel_powerless?' do
        range1, range2, range3 = space.ranges
        [0, 1].repeated_permutation(3) do |i, j, k|
          powerless = [false, false, false]
          color = space.constructor(range1[i], range2[j], range3[k])
          it "#{color.space}(#{color.channels.join(',')}): #{powerless}" do
            COLOR_SPACES[color.space.to_sym].channels.each_with_index do |channel, index|
              expect(color.channel_powerless?(channel)).to be(powerless[index])
            end
          end
        end
      end
    end

    describe 'channel_powerless?' do
      {
        'for HWB' => {
          # If the combined `whiteness + blackness` is great than or equal to
          # `100%`, then the `hue` channel is powerless.
          described_class.new(hue: 0, whiteness: 0, blackness: 100, space: 'hwb') => [true, false, false],
          described_class.new(hue: 0, whiteness: 100, blackness: 0, space: 'hwb') => [true, false, false],
          described_class.new(hue: 0, whiteness: 50, blackness: 50, space: 'hwb') => [true, false, false],
          described_class.new(hue: 0, whiteness: 60, blackness: 60, space: 'hwb') => [true, false, false],
          described_class.new(hue: 0, whiteness: -100, blackness: 200, space: 'hwb') => [true, false, false],
          described_class.new(hue: 0, whiteness: 200, blackness: -100, space: 'hwb') => [true, false, false],
          described_class.new(hue: 100, whiteness: 0, blackness: 100, space: 'hwb') => [true, false, false],
          described_class.new(hue: 0, whiteness: 0, blackness: 0, space: 'hwb') => nil,
          described_class.new(hue: 0, whiteness: 49, blackness: 50, space: 'hwb') => nil,
          described_class.new(hue: 0, whiteness: -1, blackness: 100, space: 'hwb') => nil,
          described_class.new(hue: 100, whiteness: 0, blackness: 0, space: 'hwb') => nil
        },
        'for HSL' => {
          # If the saturation of an HSL color is 0%, then the hue component is
          # powerless.
          described_class.new(hue: 0, saturation: 0, lightness: 0, space: 'hsl') => [true, false, false],
          described_class.new(hue: 0, saturation: 0, lightness: 100, space: 'hsl') => [true, false, false],
          described_class.new(hue: 100, saturation: 0, lightness: 0, space: 'hsl') => [true, false, false],
          described_class.new(hue: 0, saturation: 100, lightness: 0, space: 'hsl') => nil,
          described_class.new(hue: 0, saturation: 100, lightness: 100, space: 'hsl') => nil,
          described_class.new(hue: 100, saturation: 100, lightness: 100, space: 'hsl') => nil,
          described_class.new(hue: 100, saturation: 100, lightness: 0, space: 'hsl') => nil
        },
        'for LCH' => {
          # If the `chroma` value is 0%, then the `hue` channel is powerless.
          described_class.new(lightness: 0, chroma: 0, hue: 0, space: 'lch') => [false, false, true],
          described_class.new(lightness: 0, chroma: 0, hue: 100, space: 'lch') => [false, false, true],
          described_class.new(lightness: 100, chroma: 0, hue: 0, space: 'lch') => [false, false, true],
          described_class.new(lightness: 0, chroma: 100, hue: 0, space: 'lch') => nil,
          described_class.new(lightness: 0, chroma: 100, hue: 100, space: 'lch') => nil,
          described_class.new(lightness: 100, chroma: 100, hue: 100, space: 'lch') => nil,
          described_class.new(lightness: 100, chroma: 100, hue: 0, space: 'lch') => nil
        },
        'for OKLCH' => {
          # If the `chroma` value is 0%, then the `hue` channel is powerless.
          described_class.new(lightness: 0, chroma: 0, hue: 0, space: 'oklch') => [false, false, true],
          described_class.new(lightness: 0, chroma: 0, hue: 100, space: 'oklch') => [false, false, true],
          described_class.new(lightness: 100, chroma: 0, hue: 0, space: 'oklch') => [false, false, true],
          described_class.new(lightness: 0, chroma: 100, hue: 0, space: 'oklch') => nil,
          described_class.new(lightness: 0, chroma: 100, hue: 100, space: 'oklch') => nil,
          described_class.new(lightness: 100, chroma: 100, hue: 100, space: 'oklch') => nil,
          described_class.new(lightness: 100, chroma: 100, hue: 0, space: 'oklch') => nil
        }
      }.each do |name, group|
        describe name do
          group.each do |color, powerless|
            powerless = [false, false, false] if powerless.nil?
            it "#{color.space}(#{color.channels.join(', ')}): #{powerless}" do
              COLOR_SPACES[color.space.to_sym].channels.each_with_index do |channel, index|
                expect(color.channel_powerless?(channel)).to be(powerless[index])
              end
            end
          end
        end
      end
    end
  end
end
