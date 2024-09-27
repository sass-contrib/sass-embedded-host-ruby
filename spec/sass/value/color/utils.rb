# frozen_string_literal: true

module ColorUtils
  module_function

  def channel_cases(ch1, ch2, ch3)
    [
      [ch1, ch2, ch3],
      [nil, ch2, ch3],
      [nil, nil, ch3],
      [ch1, nil, ch3],
      [ch1, nil, nil],
      [ch1, ch2, nil],
      [nil, ch2, nil],
      [nil, nil, nil]
    ].flat_map do |channels|
      [
        channels,
        [*channels, 1],
        [*channels, 0],
        [*channels, 0.5],
        [*channels, nil]
      ]
    end
  end

  CHANNEL_NAMES = %w[
    red
    green
    blue
    hue
    saturation
    lightness
    whiteness
    blackness
    a
    b
    x
    y
    z
    chroma
  ].freeze
end
