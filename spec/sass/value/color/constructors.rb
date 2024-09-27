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

  def legacy_rgb(red, green, blue, *args)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*args))
  end

  def rgb(red, green, blue, *args)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*args), space: 'rgb')
  end

  def legacy_hsl(hue, saturation, lightness, *args)
    Sass::Value::Color.new(hue:, saturation:, lightness:, **_alpha_to_kwargs(*args))
  end

  def hsl(hue, saturation, lightness, *args)
    Sass::Value::Color.new(hue:, saturation:, lightness:, **_alpha_to_kwargs(*args), space: 'hsl')
  end

  def legacy_hwb(hue, whiteness, blackness, *args)
    Sass::Value::Color.new(hue:, whiteness:, blackness:, **_alpha_to_kwargs(*args))
  end

  def hwb(hue, whiteness, blackness, *args)
    Sass::Value::Color.new(hue:, whiteness:, blackness:, **_alpha_to_kwargs(*args), space: 'hwb')
  end

  def lab(lightness, a, b, *args) # rubocop:disable Naming/MethodParameterName
    Sass::Value::Color.new(lightness:, a:, b:, **_alpha_to_kwargs(*args), space: 'lab')
  end

  def oklab(lightness, a, b, *args) # rubocop:disable Naming/MethodParameterName
    Sass::Value::Color.new(lightness:, a:, b:, **_alpha_to_kwargs(*args), space: 'oklab')
  end

  def lch(lightness, chroma, hue, *args)
    Sass::Value::Color.new(lightness:, chroma:, hue:, **_alpha_to_kwargs(*args), space: 'lch')
  end

  def oklch(lightness, chroma, hue, *args)
    Sass::Value::Color.new(lightness:, chroma:, hue:, **_alpha_to_kwargs(*args), space: 'oklch')
  end

  def srgb(red, green, blue, *args)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*args), space: 'srgb')
  end

  def srgb_linear(red, green, blue, *args)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*args), space: 'srgb-linear')
  end

  def rec2020(red, green, blue, *args)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*args), space: 'rec2020')
  end

  def display_p3(red, green, blue, *args)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*args), space: 'display-p3')
  end

  def a98_rgb(red, green, blue, *args)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*args), space: 'a98-rgb')
  end

  def prophoto_rgb(red, green, blue, *args)
    Sass::Value::Color.new(red:, green:, blue:, **_alpha_to_kwargs(*args), space: 'prophoto-rgb')
  end

  def xyz(x, y, z, *args) # rubocop:disable Naming/MethodParameterName
    Sass::Value::Color.new(x:, y:, z:, **_alpha_to_kwargs(*args), space: 'xyz')
  end

  def xyz_d50(x, y, z, *args) # rubocop:disable Naming/MethodParameterName
    Sass::Value::Color.new(x:, y:, z:, **_alpha_to_kwargs(*args), space: 'xyz-d50')
  end

  def xyz_d65(x, y, z, *args) # rubocop:disable Naming/MethodParameterName
    Sass::Value::Color.new(x:, y:, z:, **_alpha_to_kwargs(*args), space: 'xyz-d65')
  end
end
