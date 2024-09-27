# frozen_string_literal: true

require 'spec_helper'

require_relative 'color/constructors'

describe Sass::Value::Color do
  # @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/color/legacy.test.ts
  describe 'Legacy Color' do
    def legacy_rgb(...)
      ColorConstructors.legacy_rgb(...)
    end

    def legacy_hsl(...)
      ColorConstructors.legacy_hsl(...)
    end

    def legacy_hwb(...)
      ColorConstructors.legacy_hwb(...)
    end

    describe 'construction' do
      describe 'type' do
        subject(:color) do
          legacy_rgb(18, 52, 86)
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
      end

      describe 'rgb()' do
        it 'allows valid values' do
          expect { legacy_rgb(0, 0, 0, 0) }.not_to raise_error
          expect { legacy_rgb(255, 255, 255, 1) }.not_to raise_error
        end

        it 'disallows invalid alpha values' do
          expect { legacy_rgb(0, 0, 0, -0.1) }.to raise_error(Sass::ScriptError)
          expect { legacy_rgb(0, 0, 0, 1.1) }.to raise_error(Sass::ScriptError)
        end

        it 'allows out-of-gamut values which were invalid before color 4' do
          expect { legacy_rgb(-1, 0, 0, 0) }.not_to raise_error
          expect { legacy_rgb(0, -1, 0, 0) }.not_to raise_error
          expect { legacy_rgb(0, 0, -1, 0) }.not_to raise_error
          expect { legacy_rgb(256, 0, 0, 0) }.not_to raise_error
          expect { legacy_rgb(0, 256, 0, 0) }.not_to raise_error
          expect { legacy_rgb(0, 0, 256, 0) }.not_to raise_error
        end

        it 'does not round channels to the nearest integer' do
          expect(legacy_rgb(0.1, 50.4, 90.3).channels).to fuzzy_match_array([0.1, 50.4, 90.3])
          expect(legacy_rgb(-0.1, 50.5, 90.7).channels).to fuzzy_match_array([-0.1, 50.5, 90.7])
        end
      end

      describe 'hsl()' do
        it 'allows valid values' do
          expect { legacy_hsl(0, 0, 0, 0) }.not_to raise_error
          expect { legacy_hsl(4320, 100, 100, 1) }.not_to raise_error
          expect { legacy_hsl(0, -0.1, 0, 0) }.not_to raise_error
          expect { legacy_hsl(0, 0, -0.1, 0) }.not_to raise_error
          expect { legacy_hsl(0, 100.1, 0, 0) }.not_to raise_error
          expect { legacy_hsl(0, 0, 100.1, 0) }.not_to raise_error
        end

        it 'disallows invalid alpha values' do
          expect { legacy_hsl(0, 0, 0, -0.1) }.to raise_error(Sass::ScriptError)
          expect { legacy_hsl(0, 0, 0, 1.1) }.to raise_error(Sass::ScriptError)
        end
      end

      describe 'hwb()' do
        it 'allows valid values' do
          expect { legacy_hwb(0, 0, 0, 0) }.not_to raise_error
          expect { legacy_hwb(4320, 100, 100, 1) }.not_to raise_error
          expect { legacy_hwb(0, -0.1, 0, 0) }.not_to raise_error
          expect { legacy_hwb(0, 0, -0.1, 0) }.not_to raise_error
          expect { legacy_hwb(0, 100.1, 0, 0) }.not_to raise_error
          expect { legacy_hwb(0, 0, 100.1, 0) }.not_to raise_error
        end

        it 'disallows invalid alpha values' do
          expect { legacy_hwb(0, 0, 0, -0.1) }.to raise_error(Sass::ScriptError)
          expect { legacy_hwb(0, 0, 0, 1.1) }.to raise_error(Sass::ScriptError)
        end
      end
    end

    describe 'an RGB color' do
      subject(:color) do
        legacy_rgb(18, 52, 86)
      end

      it 'has RGB channels' do
        expect(color.red).to eq(18)
        expect(color.green).to eq(52)
        expect(color.blue).to eq(86)
      end

      it 'has HSL channels' do
        expect(color.hue).to eq(210)
        expect(color.saturation).to eq(65.3846153846154)
        expect(color.lightness).to eq(20.392156862745097)
      end

      it 'has HWB channels' do
        expect(color.hue).to eq(210)
        expect(color.whiteness).to eq(7.0588235294117645)
        expect(color.blackness).to eq(66.27450980392157)
      end

      it 'has an alpha channel' do
        expect(color.alpha).to eq(1)
      end

      it 'equals the same color even in a different color space' do
        expect(color).to eq(legacy_rgb(18, 52, 86))
        expect(color).to eq(legacy_hsl(210, 65.3846153846154, 20.392156862745097))
        expect(color).to eq(legacy_hwb(210, 7.0588235294117645, 66.27450980392157))
      end
    end

    describe 'an HSL color' do
      subject(:color) do
        legacy_hsl(120, 42, 42)
      end

      it 'has RGB channels' do
        expect(color.red).to eq(62)
        expect(color.green).to eq(152)
        expect(color.blue).to eq(62)
      end

      it 'has HSL channels' do
        expect(color.hue).to eq(120)
        expect(color.saturation).to eq(42)
        expect(color.lightness).to eq(42)
      end

      it 'has HWB channels' do
        expect(color.hue).to eq(120)
        expect(color.whiteness).to eq(24.36000000000000)
        expect(color.blackness).to eq(40.36000000000001)
      end

      it 'has an alpha channel' do
        expect(color.alpha).to eq(1)
      end

      it 'equals the same color even in a different color space' do
        expect(color).to eq(legacy_rgb(62.118, 152.082, 62.118))
        expect(color).to eq(legacy_hsl(120, 42, 42))
        expect(color).to eq(legacy_hwb(120, 24.36, 40.36))
      end

      it 'allows negative hue' do
        expect(legacy_hsl(-240, 42, 42).hue).to be(120)
        expect(legacy_hsl(-240, 42, 42)).to eq(color)
      end
    end

    describe 'an HWB color' do
      subject(:color) do
        legacy_hwb(120, 42, 42)
      end

      it 'has RGB channels' do
        expect(color.red).to eq(107)
        expect(color.green).to eq(148)
        expect(color.blue).to eq(107)
      end

      it 'has HSL channels' do
        expect(color.hue).to eq(120)
        expect(color.saturation).to eq(16.000000000000014)
        expect(color.lightness).to eq(50)
      end

      it 'has HWB channels' do
        expect(color.hue).to eq(120)
        expect(color.whiteness).to eq(42)
        expect(color.blackness).to eq(42)
      end

      it 'has an alpha channel' do
        expect(color.alpha).to eq(1)
      end

      it 'equals the same color even in a different color space' do
        expect(color).to eq(legacy_rgb(107.1, 147.9, 107.1))
        expect(color).to eq(legacy_hsl(120, 16, 50))
        expect(color).to eq(legacy_hwb(120, 42, 42))
      end

      it 'allows negative hue' do
        expect(legacy_hwb(-240, 42, 42).hue).to eq(120)
        expect(legacy_hwb(-240, 42, 42)).to eq(color)
      end
    end

    describe 'changing color values' do
      describe 'change() for RGB' do
        subject(:color) do
          legacy_rgb(18, 52, 86)
        end

        it 'changes RGB values' do
          expect(color.change(red: 0)).to eq(legacy_rgb(0, 52, 86))
          expect(color.change(green: 0)).to eq(legacy_rgb(18, 0, 86))
          expect(color.change(blue: 0)).to eq(legacy_rgb(18, 52, 0))
          expect(color.change(alpha: 0.5)).to eq(legacy_rgb(18, 52, 86, 0.5))
          expect(color.change(red: 0, green: 0, blue: 0, alpha: 0.5)).to eq(legacy_rgb(0, 0, 0, 0.5))
        end

        it 'allows valid values' do
          expect(color.change(red: 0).channel('red')).to eq(0)
          expect(color.change(red: 255).channel('red')).to eq(255)
          expect(color.change(green: 0).channel('green')).to eq(0)
          expect(color.change(green: 255).channel('green')).to eq(255)
          expect(color.change(blue: 0).channel('blue')).to eq(0)
          expect(color.change(blue: 255).channel('blue')).to eq(255)
          expect(color.change(alpha: 0).alpha).to eq(0)
          expect(color.change(alpha: 1).alpha).to eq(1)
          expect(color.change(red: nil).channel('red')).to eq(18)
        end

        it 'allows out of range values which were invalid before color 4' do
          expect { color.change(red: -1) }.not_to raise_error
          expect { color.change(red: 256) }.not_to raise_error
          expect { color.change(green: -1) }.not_to raise_error
          expect { color.change(green: 256) }.not_to raise_error
          expect { color.change(blue: -1) }.not_to raise_error
          expect { color.change(blue: 256) }.not_to raise_error
        end

        it 'disallows invalid alpha values' do
          expect { color.change(alpha: -0.1) }.to raise_error(Sass::ScriptError)
          expect { color.change(alpha: 1.1) }.to raise_error(Sass::ScriptError)
        end

        it 'does not round channels to the nearest integer' do
          expect(color.change(red: 0.1, green: 50.4, blue: 90.3).channels).to fuzzy_match_array([0.1, 50.4, 90.3])
          expect(color.change(red: -0.1, green: 50.5, blue: 90.9).channels).to fuzzy_match_array([-0.1, 50.5, 90.9])
        end
      end

      describe 'change() for HSL' do
        subject(:color) do
          legacy_hsl(210, 65.3846153846154, 20.392156862745097)
        end

        it 'changes HSL values' do
          expect(color.change(hue: 120)).to eq(legacy_hsl(120, 65.3846153846154, 20.392156862745097))
          expect(color.change(hue: -120)).to eq(legacy_hsl(240, 65.3846153846154, 20.392156862745097))
          expect(color.change(saturation: 42)).to eq(legacy_hsl(210, 42, 20.392156862745097))
          expect(color.change(lightness: 42)).to eq(legacy_hsl(210, 65.3846153846154, 42))
          expect(color.change(alpha: 0.5)).to eq(legacy_hsl(210, 65.3846153846154, 20.392156862745097, 0.5))
          expect(color.change(hue: 120, saturation: 42, lightness: 42, alpha: 0.5)).to eq(legacy_hsl(120, 42, 42, 0.5))
        end

        it 'allows valid values' do
          expect(color.change(saturation: 0).channel('saturation')).to eq(0)
          expect(color.change(saturation: 100).channel('saturation')).to eq(100)
          expect(color.change(lightness: 0).channel('lightness')).to eq(0)
          expect(color.change(lightness: 100).channel('lightness')).to eq(100)
          expect(color.change(alpha: 0).alpha).to eq(0)
          expect(color.change(alpha: 1).alpha).to eq(1)
          expect(color.change(lightness: -0.1).channel('lightness')).to eq(-0.1)
          expect(color.change(lightness: 100.1).channel('lightness')).to eq(100.1)
          expect(color.change(hue: nil).channel('hue')).to eq(210)
        end

        it 'disallows invalid alpha values' do
          expect { color.change(alpha: -0.1) }.to raise_error(Sass::ScriptError)
          expect { color.change(alpha: 1.1) }.to raise_error(Sass::ScriptError)
        end
      end

      describe 'change() for HWB' do
        subject(:color) do
          legacy_hwb(210, 7.0588235294117645, 66.27450980392157)
        end

        it 'changes HWB values' do
          expect(color.change(hue: 120)).to eq(legacy_hwb(120, 7.0588235294117645, 66.27450980392157))
          expect(color.change(hue: -120)).to eq(legacy_hwb(240, 7.0588235294117645, 66.27450980392157))
          expect(color.change(whiteness: 42)).to eq(legacy_hwb(210, 42, 66.27450980392157))
          expect(color.change(whiteness: 50)).to eq(legacy_hwb(210, 50, 66.27450980392157))
          expect(color.change(blackness: 42)).to eq(legacy_hwb(210, 7.0588235294117645, 42))
          expect(color.change(alpha: 0.5)).to eq(legacy_hwb(210, 7.0588235294117645, 66.27450980392157, 0.5))
          expect(color.change(hue: 120, whiteness: 42, blackness: 42, alpha: 0.5)).to eq(legacy_hwb(120, 42, 42, 0.5))
        end

        it 'allows valid values' do
          expect(color.change(whiteness: 0).channel('whiteness')).to eq(0)
          expect(color.change(whiteness: 100).channel('whiteness')).to eq(100)
          expect(color.change(blackness: 0).channel('blackness')).to eq(0)
          expect(color.change(blackness: 100).channel('blackness')).to eq(100)
          expect(color.change(alpha: 0).alpha).to eq(0)
          expect(color.change(alpha: 1).alpha).to eq(1)
          expect(color.change(hue: nil).channel('hue')).to eq(210)
        end

        it 'disallows invalid alpha values' do
          expect { color.change(alpha: -0.1) }.to raise_error(Sass::ScriptError)
          expect { color.change(alpha: 1.1) }.to raise_error(Sass::ScriptError)
        end
      end

      describe 'change(alpha:)' do
        subject(:color) do
          legacy_rgb(18, 52, 86)
        end

        it 'changes the alpha value' do
          expect(color.change(alpha: 0.5)).to eq(legacy_rgb(18, 52, 86, 0.5))
        end

        it 'allows valid alphas' do
          expect(color.change(alpha: 0).alpha).to eq(0)
          expect(color.change(alpha: 1).alpha).to eq(1)
        end

        it 'rejects invalid alphas' do
          expect { color.change(alpha: -0.1) }.to raise_error(Sass::ScriptError)
          expect { color.change(alpha: 1.1) }.to raise_error(Sass::ScriptError)
        end
      end
    end
  end
end
