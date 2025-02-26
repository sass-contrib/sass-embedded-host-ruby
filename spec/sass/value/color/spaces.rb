# frozen_string_literal: true

require_relative 'constructors'

class ColorSpace
  def initialize(hash)
    @hash = hash
  end

  def method_missing(symbol, ...)
    return super unless @hash.key?(symbol)

    if symbol == :constructor
      ColorConstructors.send(@hash[symbol], ...)
    else
      @hash[symbol]
    end
  end

  def respond_to_missing?(symbol, _include_all)
    @hash.key?(symbol)
  end
end

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/color/spaces.ts
COLOR_SPACES = {
  lab: {
    constructor: :lab,
    name: 'lab',
    is_legacy: false,
    is_polar: false,
    pink: [78.27047872644108, 35.20288139978972, 1.0168442562641822],
    blue: [38.957924659568256, -15.169546354833418, -17.792483560001216],
    channels: %w[lightness a b],
    ranges: [
      [0, 100],
      [-125, 125],
      [-125, 125]
    ],
    has_out_of_gamut: false,
    gamut_examples: [
      [
        [50, 150, 150],
        [50, 150, 150]
      ]
    ]
  },
  oklab: {
    constructor: :oklab,
    name: 'oklab',
    is_legacy: false,
    is_polar: false,
    pink: [0.8241000051752044, 0.10608808769190603, 0.0015900461037656743],
    blue: [0.47120000698576636, -0.05111706553856424, -0.048406668724564006],
    channels: %w[lightness a b],
    ranges: [
      [0, 1],
      [-0.4, 0.4],
      [-0.4, 0.4]
    ],
    has_out_of_gamut: false,
    gamut_examples: [
      [
        [0.5, 1, 1],
        [0.5, 1, 1]
      ]
    ]
  },
  lch: {
    constructor: :lch,
    name: 'lch',
    is_legacy: false,
    is_polar: true,
    pink: [78.27047872644108, 35.21756424128674, 1.6545432253797117],
    blue: [38.957924659568256, 23.381351711232465, 229.54969639237788],
    channels: %w[lightness chroma hue],
    has_powerless: true,
    ranges: [
      [0, 100],
      [0, 150],
      [0, 360]
    ],
    has_out_of_gamut: false,
    gamut_examples: [
      [
        [50, 200, 480],
        [50, 200, 480]
      ]
    ]
  },
  oklch: {
    constructor: :oklch,
    name: 'oklch',
    is_legacy: false,
    is_polar: true,
    pink: [0.8241000051752044, 0.1061000028121472, 0.8586836854624949],
    blue: [0.47120000698576636, 0.07039999976053661, 223.44001107929404],
    channels: %w[lightness chroma hue],
    has_powerless: true,
    ranges: [
      [0, 1],
      [0, 0.4],
      [0, 360]
    ],
    has_out_of_gamut: false,
    gamut_examples: [
      [
        [0.5, 1, 480],
        [0.5, 1, 480]
      ]
    ]
  },
  srgb: {
    constructor: :srgb,
    name: 'srgb',
    is_legacy: false,
    is_polar: false,
    pink: [0.9999785463111587, 0.6599448662991679, 0.7583730171250161],
    blue: [0.14900142239759614, 0.39063941586401707, 0.47119722379126755],
    channels: %w[red green blue],
    ranges: [
      [0, 1],
      [0, 1],
      [0, 1]
    ],
    has_out_of_gamut: true,
    gamut_examples: [
      [[0.5, 2, 2], { clip: [0.5, 1, 1], 'local-minde': [1, 1, 1] }]
    ]
  },
  'srgb-linear': {
    constructor: :srgb_linear,
    name: 'srgb-linear',
    is_legacy: false,
    is_polar: false,
    pink: [0.9999511960945082, 0.39305038114762536, 0.5356603778005656],
    blue: [0.019378214827482948, 0.12640222770203852, 0.18834349393523495],
    channels: %w[red green blue],
    ranges: [
      [0, 1],
      [0, 1],
      [0, 1]
    ],
    has_out_of_gamut: true,
    gamut_examples: [
      [[0.5, 2, 2], { clip: [0.5, 1, 1], 'local-minde': [1, 1, 1] }]
    ]
  },
  'display-p3': {
    constructor: :display_p3,
    name: 'display-p3',
    is_legacy: false,
    is_polar: false,
    pink: [0.9510333333617188, 0.6749909745845027, 0.7568568353546363],
    blue: [0.21620126176161275, 0.38537730537965537, 0.46251697991685353],
    channels: %w[red green blue],
    ranges: [
      [0, 1],
      [0, 1],
      [0, 1]
    ],
    has_out_of_gamut: true,
    gamut_examples: [
      [[0.5, 2, 2], { clip: [0.5, 1, 1], 'local-minde': [1, 1, 1] }]
    ]
  },
  'a98-rgb': {
    constructor: :a98_rgb,
    name: 'a98-rgb',
    is_legacy: false,
    is_polar: false,
    pink: [0.9172837001828322, 0.6540226622083833, 0.749114439711684],
    blue: [0.2557909283504703, 0.3904466064332277, 0.4651826475952292],
    channels: %w[red green blue],
    ranges: [
      [0, 1],
      [0, 1],
      [0, 1]
    ],
    has_out_of_gamut: true,
    gamut_examples: [
      [[0.5, 2, 2], { clip: [0.5, 1, 1], 'local-minde': [1, 1, 1] }]
    ]
  },
  'prophoto-rgb': {
    constructor: :prophoto_rgb,
    name: 'prophoto-rgb',
    is_legacy: false,
    is_polar: false,
    pink: [0.842345736209146, 0.6470539622987259, 0.7003583323790157],
    blue: [0.24317987809516806, 0.304508209543027, 0.3835687899657161],
    channels: %w[red green blue],
    ranges: [
      [0, 1],
      [0, 1],
      [0, 1]
    ],
    has_out_of_gamut: true,
    gamut_examples: [
      [[0.5, 2, 2], { clip: [0.5, 1, 1], 'local-minde': [1, 1, 1] }]
    ]
  },
  rec2020: {
    constructor: :rec2020,
    name: 'rec2020',
    is_legacy: false,
    is_polar: false,
    pink: [0.883711832123552, 0.6578067923850561, 0.7273197917658352],
    blue: [0.21511227405324085, 0.3236397315019512, 0.4090033869684574],
    channels: %w[red green blue],
    ranges: [
      [0, 1],
      [0, 1],
      [0, 1]
    ],
    has_out_of_gamut: true,
    gamut_examples: [
      [[0.5, 2, 2], { clip: [0.5, 1, 1], 'local-minde': [1, 1, 1] }]
    ]
  },
  xyz: {
    constructor: :xyz,
    name: 'xyz',
    is_legacy: false,
    is_polar: false,
    pink: [0.6495957411726918, 0.5323965129525022, 0.575341840710865],
    blue: [0.08718323686632441, 0.1081164314257634, 0.19446762910683627],
    channels: %w[x y z],
    ranges: [
      [0, 1],
      [0, 1],
      [0, 1]
    ],
    has_out_of_gamut: false,
    gamut_examples: [
      [
        [0.5, 2, 2],
        [0.5, 2, 2]
      ]
    ]
  },
  'xyz-d50': {
    constructor: :xyz_d50,
    name: 'xyz-d50',
    is_legacy: false,
    is_polar: false,
    pink: [0.6640698533004004, 0.5367266625281086, 0.43459582467202973],
    blue: [0.08408207405980274, 0.10634498282797152, 0.14703708427207543],
    channels: %w[x y z],
    ranges: [
      [0, 1],
      [0, 1],
      [0, 1]
    ],
    has_out_of_gamut: false,
    gamut_examples: [
      [
        [0.5, 2, 2],
        [0.5, 2, 2]
      ]
    ]
  },
  'xyz-d65': {
    constructor: :xyz_d65,
    name: 'xyz',
    is_legacy: false,
    is_polar: false,
    pink: [0.6495957411726918, 0.5323965129525022, 0.575341840710865],
    blue: [0.08718323686632441, 0.1081164314257634, 0.19446762910683627],
    channels: %w[x y z],
    ranges: [
      [0, 1],
      [0, 1],
      [0, 1]
    ],
    has_out_of_gamut: false,
    gamut_examples: [
      [
        [0.5, 2, 2],
        [0.5, 2, 2]
      ]
    ]
  },
  rgb: {
    constructor: :rgb,
    name: 'rgb',
    is_legacy: true,
    is_polar: false,
    pink: [254.99452930934547, 168.28594090628783, 193.3851193668791],
    blue: [37.99536271138702, 99.61305104532435, 120.15529206677323],
    channels: %w[red green blue],
    ranges: [
      [0, 255],
      [0, 255],
      [0, 255]
    ],
    has_out_of_gamut: true,
    gamut_examples: [
      [
        [300, 300, 300],
        [255, 255, 255]
      ]
    ]
  },
  hsl: {
    constructor: :hsl,
    name: 'hsl',
    is_legacy: true,
    is_polar: true,
    pink: [342.63204677447646, 99.98738302509679, 82.99617063051633],
    blue: [195.0016494775154, 51.95041997811069, 31.009932309443183],
    channels: %w[hue saturation lightness],
    has_powerless: true,
    ranges: [
      [0, 360],
      [0, 100],
      [0, 100]
    ],
    has_out_of_gamut: true,
    gamut_examples: [
      [
        [0.5, 110, 50],
        {
          clip: [0.5, 100, 50],
          'local-minde': [2.9140266584158057, 100, 52.05146824961835]
        }
      ]
    ]
  },
  hwb: {
    constructor: :hwb,
    name: 'hwb',
    is_legacy: true,
    is_polar: true,
    pink: [342.63204677447646, 65.9944866299168, 0.002145368884129084],
    blue: [195.0016494775154, 14.900142239759612, 52.880277620873244],
    channels: %w[hue whiteness blackness],
    has_powerless: true,
    ranges: [
      [0, 360],
      [0, 100],
      [0, 100]
    ],
    has_out_of_gamut: true,
    gamut_examples: [
      [
        [0.5, -3, -7],
        {
          clip: [0.5, 0, 0],
          'local-minde': [3.492122559065345, 11.266517197307957, 0]
        }
      ]
    ]
  }
}.transform_values! { |value| ColorSpace.new(value) }.freeze
