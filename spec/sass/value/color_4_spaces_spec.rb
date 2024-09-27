# frozen_string_literal: true

require 'spec_helper'

require_relative 'color/spaces'

describe Sass::Value::Color do
  # @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/color/color-4-spaces.test.ts
  describe 'Color 4 Spaces' do
    COLOR_SPACES.each_value do |space|
      describe space.name do
        subject(:color) do
          space.constructor(*space.pink)
        end

        it 'is a value' do
          expect(color).to be_a(Sass::Value)
        end

        it 'is a color' do
          expect(color).to be_a(described_class)
          expect(color.assert_color).to be(color)
        end

        it "isn't any other type" do
          expect { color.assert_boolean }.to raise_error(Sass::ScriptError)
          expect { color.assert_calculation }.to raise_error(Sass::ScriptError)
          expect { color.assert_function }.to raise_error(Sass::ScriptError)
          expect { color.assert_map }.to raise_error(Sass::ScriptError)
          expect(color.to_map).to be_nil
          expect { color.assert_mixin }.to raise_error(Sass::ScriptError)
          expect { color.assert_number }.to raise_error(Sass::ScriptError)
          expect { color.assert_string }.to raise_error(Sass::ScriptError)
        end

        describe 'allows out-of-range channel values' do
          average1 = (space.ranges[0][0] + space.ranges[0][1]) / 2.0
          average2 = (space.ranges[1][0] + space.ranges[1][1]) / 2.0
          average3 = (space.ranges[2][0] + space.ranges[2][1]) / 2.0

          3.times do |i|
            channel = space.channels[i]
            next if channel == 'hue'

            it "for #{channel}" do
              above_range = space.ranges[i][1] + 10
              below_range = space.ranges[i][0] - 10
              above = space.constructor(
                i == 0 ? above_range : average1,
                i == 1 ? above_range : average2,
                i == 2 ? above_range : average3
              )
              below = space.constructor(
                i == 0 ? below_range : average1,
                i == 1 ? below_range : average2,
                i == 2 ? below_range : average3
              )

              expect(above.channels[i]).to eq(above_range)

              case channel
              when 'saturation'
                expect(below.channels[i]).to eq(below_range.abs)
                expect(below.channels[0]).to eq((average1 + 180) % 360)
              when 'chroma'
                expect(below.channels[i]).to eq(below_range.abs)
                expect(below.channels[2]).to eq((average3 + 180) % 360)
              else
                expect(below.channels[i]).to eq(below_range)
              end
            end
          end
        end

        it 'throws on invalid alpha' do
          expect { space.constructor(*space.pink, -1) }.to raise_error(Sass::ScriptError)
          expect { space.constructor(*space.pink, 1.1) }.to raise_error(Sass::ScriptError)
        end

        it "returns name for #{space.name}" do
          expect(color.space).to eq(space.name)
        end

        it "legacy? returns #{space.is_legacy} for #{space.name}" do
          expect(color.legacy?).to be(space.is_legacy)
        end
      end
    end
  end
end
