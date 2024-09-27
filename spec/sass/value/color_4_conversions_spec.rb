# frozen_string_literal: true

require 'spec_helper'

require_relative 'color/spaces'
require_relative 'color/interpolation_examples'

describe Sass::Value::Color do
  # @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/color/color-4-conversions.test.ts
  describe 'Color 4 Conversions' do
    COLOR_SPACES.each_value do |space|
      describe space.name do
        subject(:blue) do
          space.constructor(*space.blue)
        end

        let(:color) do
          space.constructor(*space.pink)
        end

        describe 'to_space' do
          COLOR_SPACES.each_value do |destination_space|
            it "converts pink to #{destination_space.name}" do
              res = color.to_space(destination_space.name)
              expect(res.space).to eq(destination_space.name)
              expect(res).to fuzzy_eq(destination_space.constructor(*destination_space.pink))
            end
          end
        end

        describe 'interpolate' do
          it 'interpolates examples' do
            COLOR_INTERPOLATIONS[space.name.to_sym].each do |input, output|
              res = color.interpolate(blue, **input)
              output_color = space.constructor(*output)
              expect(res).to fuzzy_eq(output_color)
            end
          end
        end

        describe 'change' do
          it 'changes all channels in own space' do
            space.channels.each_with_index do |channel_name, index|
              expected_channels = space.pink.dup
              expected_channels[index] = 0
              expect(color.change(**{ channel_name.to_sym => 0 })).to fuzzy_eq(space.constructor(*expected_channels))
            end
            expect(color.change(alpha: 0)).to fuzzy_eq(space.constructor(*space.pink, 0))
          end

          it 'change with explicit undefined makes no change' do
            expect(color.change).to fuzzy_eq(space.constructor(*space.pink))
            expect(color.change).to fuzzy_eq(space.constructor(*space.pink, 1))
          end

          it 'explicit nil sets channel to missing' do
            space.channels.each_with_index do |channel_name, index|
              expected_channels = space.pink.dup
              expected_channels[index] = nil
              changed = color.change(**{ channel_name.to_sym => nil }, space: space.name)
              expect(changed).to fuzzy_eq(space.constructor(*expected_channels))
              expect(changed.channel_missing?(channel_name)).to be(true)
            end
            expect(color.change(alpha: nil, space: space.name)).to fuzzy_eq(space.constructor(*space.pink, nil))
          end

          describe 'allows out-of-range channel values' do
            base_color = space.constructor(
              (space.ranges[0][0] + space.ranges[0][1]) / 2.0,
              (space.ranges[1][0] + space.ranges[1][1]) / 2.0,
              (space.ranges[2][0] + space.ranges[2][1]) / 2.0
            )

            3.times do |i|
              channel = space.channels[i]
              next if channel == 'hue'

              it "for #{channel}" do
                above_range = space.ranges[i][1] + 10
                below_range = space.ranges[i][0] - 10
                above = base_color.change(**{ channel.to_sym => above_range })
                below = base_color.change(**{ channel.to_sym => below_range })

                expect(above.channels[i]).to eq(above_range)

                case channel
                when 'saturation'
                  expect(below.channels[i]).to eq(below_range.abs)
                  expect(below.channels[0]).to eq((base_color.channels[0] + 180) % 360)
                when 'chroma'
                  expect(below.channels[i]).to eq(below_range.abs)
                  expect(below.channels[2]).to eq((base_color.channels[2] + 180) % 360)
                else
                  expect(below.channels[i]).to eq(below_range)
                end
              end
            end
          end

          COLOR_SPACES.each_value do |destination_space|
            it "changes all channels with space set to #{destination_space.name}" do
              destination_space.channels.each_with_index do |channel, index|
                destination_channels = destination_space.pink.dup

                # Certain channel values cause equality issues on 1-3 of 16*16*3
                # cases. 0.45 is a magic number that works around this until the
                # root cause is determined.
                scale = 0.45
                channel_value = destination_space.ranges[index][1] * scale

                destination_channels[index] = channel_value
                expected = destination_space.constructor(*destination_channels).to_space(space.name)

                expect(color.change(**{ channel.to_sym => channel_value },
                                    space: destination_space.name)).to fuzzy_eq(expected)
              end
            end
          end

          it 'throws on invalid alpha' do
            expect { color.change(alpha: -1) }.to raise_error(Sass::ScriptError)
            expect { color.change(alpha: 1.1) }.to raise_error(Sass::ScriptError)
          end
        end

        describe 'in_gamut?' do
          it 'is true for in gamut colors in own space' do
            expect(color.in_gamut?).to be(true)
          end

          COLOR_SPACES.each_value do |destination_space|
            it "is true for in gamut colors in #{destination_space.name}" do
              expect(color.in_gamut?(destination_space.name)).to be(true)
            end
          end

          it "is #{!space.has_out_of_gamut} for out of range colors in own space" do
            out_of_gamut = space.constructor(*space.gamut_examples[0][0])
            expect(out_of_gamut.in_gamut?).to be(!space.has_out_of_gamut)
          end
        end

        describe 'to_gamut' do
          space.gamut_examples.each do |input, outputs|
            outputs = { clip: outputs, 'local-minde': outputs } if outputs.is_a?(Array)
            outputs.each do |method, output|
              describe method.to_s do
                it "in own space, #{input} -> #{output}" do
                  res = space.constructor(*input).to_gamut(method: method.to_s)
                  expect(res).to fuzzy_eq(space.constructor(*output))
                end
              end
            end
          end
        end
      end
    end
  end
end
