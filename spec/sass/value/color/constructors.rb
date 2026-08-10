# frozen_string_literal: true

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/color/constructors.ts
module ColorConstructors
  module_function

  def _alpha_to_kwargs(*args)
    case args.length
    when 0
      {}
    when 1
      { alpha: args[0] }
    else
      raise ArgumentError
    end
  end

  def legacy_rgb(red, green, blue, *)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*))
  end

  def rgb(red, green, blue, *)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*), space: 'rgb')
  end

  def legacy_hsl(hue, saturation, lightness, *)
    Sass::Value::Color.new(hue:, saturation:, lightness:, **_alpha_to_kwargs(*))
  end

  def hsl(hue, saturation, lightness, *)
    Sass::Value::Color.new(hue:, saturation:, lightness:, **_alpha_to_kwargs(*), space: 'hsl')
  end

  def legacy_hwb(hue, whiteness, blackness, *)
    Sass::Value::Color.new(hue:, whiteness:, blackness:, **_alpha_to_kwargs(*))
  end

  def hwb(hue, whiteness, blackness, *)
    Sass::Value::Color.new(hue:, whiteness:, blackness:, **_alpha_to_kwargs(*), space: 'hwb')
  end

  def lab(lightness, a, b, *) # rubocop:disable Naming/MethodParameterName
    Sass::Value::Color.new(lightness:, a:, b:, **_alpha_to_kwargs(*), space: 'lab')
  end

  def oklab(lightness, a, b, *) # rubocop:disable Naming/MethodParameterName
    Sass::Value::Color.new(lightness:, a:, b:, **_alpha_to_kwargs(*), space: 'oklab')
  end

  def lch(lightness, chroma, hue, *)
    Sass::Value::Color.new(lightness:, chroma:, hue:, **_alpha_to_kwargs(*), space: 'lch')
  end

  def oklch(lightness, chroma, hue, *)
    Sass::Value::Color.new(lightness:, chroma:, hue:, **_alpha_to_kwargs(*), space: 'oklch')
  end

  def srgb(red, green, blue, *)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*), space: 'srgb')
  end

  def srgb_linear(red, green, blue, *)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*), space: 'srgb-linear')
  end

  def rec2020(red, green, blue, *)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*), space: 'rec2020')
  end

  def display_p3(red, green, blue, *)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*), space: 'display-p3')
  end

  def display_p3_linear(red, green, blue, *)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*), space: 'display-p3-linear')
  end

  def a98_rgb(red, green, blue, *)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*), space: 'a98-rgb')
  end

  def prophoto_rgb(red, green, blue, *)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*), space: 'prophoto-rgb')
  end

  def xyz(x, y, z, *) # rubocop:disable Naming/MethodParameterName
    Sass::Value::Color.new(x:, y:, z:, **_alpha_to_kwargs(*), space: 'xyz')
  end

  def xyz_d50(x, y, z, *) # rubocop:disable Naming/MethodParameterName
    Sass::Value::Color.new(x:, y:, z:, **_alpha_to_kwargs(*), space: 'xyz-d50')
  end

  def xyz_d65(x, y, z, *) # rubocop:disable Naming/MethodParameterName
    Sass::Value::Color.new(x:, y:, z:, **_alpha_to_kwargs(*), space: 'xyz-d65')
  end
end
