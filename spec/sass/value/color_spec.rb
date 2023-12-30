# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/color.test.ts
describe Sass::Value::Color do
  def rgb(red, green, blue, alpha = nil)
    Sass::Value::Color.new(red:, green:, blue:, alpha:)
  end

  def hsl(hue, saturation, lightness, alpha = nil)
    Sass::Value::Color.new(hue:, saturation:, lightness:, alpha:)
  end

  def hwb(hue, whiteness, blackness, alpha = nil)
    Sass::Value::Color.new(hue:, whiteness:, blackness:, alpha:)
  end

  describe 'construction' do
    describe 'type' do
      let(:color) do
        rgb(18, 52, 86)
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
        expect { rgb(0, 0, 0, 0) }.not_to raise_error
        expect { rgb(255, 255, 255, 1) }.not_to raise_error
      end

      it 'disallows invalid values' do
        expect { rgb(-1, 0, 0, 0) }.to raise_error(Sass::ScriptError)
        expect { rgb(0, -1, 0, 0) }.to raise_error(Sass::ScriptError)
        expect { rgb(0, 0, -1, 0) }.to raise_error(Sass::ScriptError)
        expect { rgb(0, 0, 0, -0.1) }.to raise_error(Sass::ScriptError)
        expect { rgb(256, 0, 0, 0) }.to raise_error(Sass::ScriptError)
        expect { rgb(0, 256, 0, 0) }.to raise_error(Sass::ScriptError)
        expect { rgb(0, 0, 256, 0) }.to raise_error(Sass::ScriptError)
        expect { rgb(0, 0, 0, 1.1) }.to raise_error(Sass::ScriptError)
      end

      it 'rounds channels to the nearest integer' do
        expect(rgb(0.1, 50.4, 90.3)).to eq(rgb(0, 50, 90))
        expect(rgb(-0.1, 50.5, 90.7)).to eq(rgb(0, 51, 91))
      end
    end

    describe 'hsl()' do
      it 'allows valid values' do
        expect { hsl(0, 0, 0, 0) }.not_to raise_error
        expect { hsl(4320, 100, 100, 1) }.not_to raise_error
      end

      it 'disallows invalid values' do
        expect { hsl(0, -0.1, 0, 0) }.to raise_error(Sass::ScriptError)
        expect { hsl(0, 0, -0.1, 0) }.to raise_error(Sass::ScriptError)
        expect { hsl(0, 0, 0, -0.1) }.to raise_error(Sass::ScriptError)
        expect { hsl(0, 100.1, 0, 0) }.to raise_error(Sass::ScriptError)
        expect { hsl(0, 0, 100.1, 0) }.to raise_error(Sass::ScriptError)
        expect { hsl(0, 0, 0, 1.1) }.to raise_error(Sass::ScriptError)
      end
    end

    describe 'hwb()' do
      it 'allows valid values' do
        expect { hwb(0, 0, 0, 0) }.not_to raise_error
        expect { hwb(4320, 100, 100, 1) }.not_to raise_error
      end

      it 'disallows invalid values' do
        expect { hwb(0, -0.1, 0, 0) }.to raise_error(Sass::ScriptError)
        expect { hwb(0, 0, -0.1, 0) }.to raise_error(Sass::ScriptError)
        expect { hwb(0, 0, 0, -0.1) }.to raise_error(Sass::ScriptError)
        expect { hwb(0, 100.1, 0, 0) }.to raise_error(Sass::ScriptError)
        expect { hwb(0, 0, 100.1, 0) }.to raise_error(Sass::ScriptError)
        expect { hwb(0, 0, 0, 1.1) }.to raise_error(Sass::ScriptError)
      end
    end
  end

  describe 'an RGB color' do
    let(:color) do
      rgb(18, 52, 86)
    end

    it 'has RGB channels' do
      expect(color.red).to eq(18)
      expect(color.green).to eq(52)
      expect(color.blue).to eq(86)
    end

    it 'has HSL channels' do
      expect(color.hue).to eq(210)
      expect(color.saturation).to eq(65.38461538461539)
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

    it 'equals the same color' do
      expect(color).to eq(rgb(18, 52, 86))
      expect(color).to eq(hsl(210, 65.38461538461539, 20.392156862745097))
      expect(color).to eq(hwb(210, 7.0588235294117645, 66.27450980392157))
    end
  end

  describe 'an HSL color' do
    let(:color) do
      hsl(120, 42, 42)
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
      expect(color.whiteness).to eq(24.313725490196077)
      expect(color.blackness).to eq(40.3921568627451)
    end

    it 'has an alpha channel' do
      expect(color.alpha).to eq(1)
    end

    it 'equals the same color' do
      expect(color).to eq(rgb(62, 152, 62))
      expect(color).to eq(hsl(120, 42, 42))
      expect(color).to eq(hwb(120, 24.313725490196077, 40.3921568627451))
    end

    it 'allows negative hue' do
      expect(hsl(-240, 42, 42).hue).to be(120)
      expect(hsl(-240, 42, 42)).to eq(color)
    end
  end

  describe 'an HWB color' do
    let(:color) do
      hwb(120, 42, 42)
    end

    it 'has RGB channels' do
      expect(color.red).to eq(107)
      expect(color.green).to eq(148)
      expect(color.blue).to eq(107)
    end

    it 'has HSL channels' do
      expect(color.hue).to eq(120)
      expect(color.saturation).to eq(16.07843137254902)
      expect(color.lightness).to eq(50)
    end

    it 'has HWB channels' do
      expect(color.hue).to eq(120)
      expect(color.whiteness).to eq(41.96078431372549)
      expect(color.blackness).to eq(41.96078431372549)
    end

    it 'has an alpha channel' do
      expect(color.alpha).to eq(1)
    end

    it 'equals the same color' do
      expect(color).to eq(rgb(107, 148, 107))
      expect(color).to eq(hsl(120, 16.078431372549026, 50))
      expect(color).to eq(hwb(120, 41.96078431372549, 41.96078431372549))
    end

    it 'allows negative hue' do
      expect(hwb(-240, 42, 42).hue).to eq(120)
      expect(hwb(-240, 42, 42)).to eq(color)
    end
  end

  describe 'changing color values' do
    let(:color) do
      rgb(18, 52, 86)
    end

    describe 'change() for RGB' do
      it 'changes RGB values' do
        expect(color.change(red: 0)).to eq(rgb(0, 52, 86))
        expect(color.change(green: 0)).to eq(rgb(18, 0, 86))
        expect(color.change(blue: 0)).to eq(rgb(18, 52, 0))
        expect(color.change(alpha: 0.5)).to eq(rgb(18, 52, 86, 0.5))
        expect(color.change(red: 0, green: 0, blue: 0, alpha: 0.5)).to eq(rgb(0, 0, 0, 0.5))
      end

      it 'allows valid values' do
        expect(color.change(red: 0).red).to eq(0)
        expect(color.change(red: 255).red).to eq(255)
        expect(color.change(green: 0).green).to eq(0)
        expect(color.change(green: 255).green).to eq(255)
        expect(color.change(blue: 0).blue).to eq(0)
        expect(color.change(blue: 255).blue).to eq(255)
        expect(color.change(alpha: 0).alpha).to eq(0)
        expect(color.change(alpha: 1).alpha).to eq(1)
      end

      it 'disallows invalid values' do
        expect { color.change(red: -1) }.to raise_error(Sass::ScriptError)
        expect { color.change(red: 256) }.to raise_error(Sass::ScriptError)
        expect { color.change(green: -1) }.to raise_error(Sass::ScriptError)
        expect { color.change(green: 256) }.to raise_error(Sass::ScriptError)
        expect { color.change(blue: -1) }.to raise_error(Sass::ScriptError)
        expect { color.change(blue: 256) }.to raise_error(Sass::ScriptError)
        expect { color.change(alpha: -0.1) }.to raise_error(Sass::ScriptError)
        expect { color.change(alpha: 1.1) }.to raise_error(Sass::ScriptError)
      end

      it 'rounds channels to the nearest integer' do
        expect(color.change(red: 0.1, green: 50.4, blue: 90.3)).to eq(rgb(0, 50, 90))
        expect(color.change(red: -0.1, green: 50.5, blue: 90.9)).to eq(rgb(0, 51, 91))
      end
    end

    describe 'change() for HSL' do
      it 'changes HSL values' do
        expect(color.change(hue: 120)).to eq(hsl(120, 65.3846153846154, 20.392156862745097))
        expect(color.change(hue: -120)).to eq(hsl(240, 65.3846153846154, 20.392156862745097))
        expect(color.change(saturation: 42)).to eq(hsl(210, 42, 20.392156862745097))
        expect(color.change(lightness: 42)).to eq(hsl(210, 65.3846153846154, 42))
        expect(color.change(alpha: 0.5)).to eq(hsl(210, 65.3846153846154, 20.392156862745097, 0.5))
        expect(color.change(hue: 120, saturation: 42, lightness: 42, alpha: 0.5)).to eq(hsl(120, 42, 42, 0.5))
      end

      it 'allows valid values' do
        expect(color.change(saturation: 0).saturation).to eq(0)
        expect(color.change(saturation: 100).saturation).to eq(100)
        expect(color.change(lightness: 0).lightness).to eq(0)
        expect(color.change(lightness: 100).lightness).to eq(100)
        expect(color.change(alpha: 0).alpha).to eq(0)
        expect(color.change(alpha: 1).alpha).to eq(1)
      end

      it 'disallows invalid values' do
        expect { color.change(saturation: -0.1) }.to raise_error(Sass::ScriptError)
        expect { color.change(saturation: 100.1) }.to raise_error(Sass::ScriptError)
        expect { color.change(lightness: -0.1) }.to raise_error(Sass::ScriptError)
        expect { color.change(lightness: 100.1) }.to raise_error(Sass::ScriptError)
        expect { color.change(alpha: -0.1) }.to raise_error(Sass::ScriptError)
        expect { color.change(alpha: 1.1) }.to raise_error(Sass::ScriptError)
      end
    end

    describe 'change() for HWB' do
      it 'changes HWB values' do
        expect(color.change(hue: 120)).to eq(hwb(120, 7.0588235294117645, 66.27450980392157))
        expect(color.change(hue: -120)).to eq(hwb(240, 7.0588235294117645, 66.27450980392157))
        expect(color.change(whiteness: 42)).to eq(hwb(210, 42, 66.27450980392157))
        expect(color.change(whiteness: 50)).to eq(hwb(210, 50, 66.27450980392157))
        expect(color.change(blackness: 42)).to eq(hwb(210, 7.0588235294117645, 42))
        expect(color.change(alpha: 0.5)).to eq(hwb(210, 7.0588235294117645, 66.27450980392157, 0.5))
        expect(color.change(hue: 120, whiteness: 42, blackness: 42, alpha: 0.5)).to eq(hwb(120, 42, 42, 0.5))
      end

      it 'allows valid values' do
        expect(color.change(whiteness: 0).whiteness).to eq(0)
        expect(color.change(whiteness: 100).whiteness).to eq(60.0)
        expect(color.change(blackness: 0).blackness).to eq(0)
        expect(color.change(blackness: 100).blackness).to eq(93.33333333333333)
        expect(color.change(alpha: 0).alpha).to eq(0)
        expect(color.change(alpha: 1).alpha).to eq(1)
      end

      it 'disallows invalid values' do
        expect { color.change(whiteness: -0.1) }.to raise_error(Sass::ScriptError)
        expect { color.change(whiteness: 100.1) }.to raise_error(Sass::ScriptError)
        expect { color.change(blackness: -0.1) }.to raise_error(Sass::ScriptError)
        expect { color.change(blackness: 100.1) }.to raise_error(Sass::ScriptError)
        expect { color.change(alpha: -0.1) }.to raise_error(Sass::ScriptError)
        expect { color.change(alpha: 1.1) }.to raise_error(Sass::ScriptError)
      end
    end

    describe 'changeAlpha()' do
      it 'changes the alpha value' do
        expect(color.change(alpha: 0.5)).to eq(rgb(18, 52, 86, 0.5))
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
