# frozen_string_literal: true

require_relative 'constructors'

# @see https://github.com/sass/sass-spec/blob/main/js-api-spec/value/color/spaces.ts
COLOR_SPACES = {
  lab: {
    constructor: :lab,
    name: 'lab',
    is_legacy: false,
    is_polar: false,
    pink: [78.27047872644108, 35.20288139978972, 1.0168442562642044],
    blue: [38.95792456574883, -15.169549415088856, -17.792484605053115],
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
    pink: [0.8241000000000002, 0.10608808442731632, 0.0015900762693974446],
    blue: [0.47120000400818335, -0.05111706453373946, -0.048406651029280656],
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
    pink: [78.27047872644108, 35.21756424128674, 1.6545432253797676],
    blue: [38.957924566, 23.38135449889311, 229.54969234595737],
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
    pink: [0.8241, 0.1061, 0.8587],
    blue: [0.47120000400818335, 0.07039998686375618, 223.44000118475142],
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
    pink: [0.9999785463111585, 0.6599448662991679, 0.758373017125016],
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
    pink: [0.999951196094508, 0.3930503811476254, 0.5356603778005655],
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
    pink: [0.9172837001828321, 0.6540226622083835, 0.7491144397116841],
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
    pink: [0.842345736209146, 0.6470539622987257, 0.7003583323790157],
    blue: [0.24317903319635056, 0.3045087255847488, 0.38356879501347535],
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
    pink: [0.8837118321235519, 0.6578067923850563, 0.7273197917658354],
    blue: [0.2151122740532409, 0.32363973150195124, 0.4090033869684574],
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
    pink: [0.6640698533004002, 0.5367266625281085, 0.4345958246720296],
    blue: [0.08408207011375313, 0.10634498228480066, 0.1470370877550857],
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
    pink: [254.9945293093454, 168.28594090628783, 193.38511936687908],
    blue: [38.144364133784602, 100.003690461188378, 120.626489290564506],
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
    pink: [342.63204677447646, 99.98738302509669, 82.99617063051632],
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
          'local-minde': [2.9140262667, 100, 52.0514687465]
        }
      ]
    ]
  },
  hwb: {
    constructor: :hwb,
    name: 'hwb',
    is_legacy: true,
    is_polar: true,
    pink: [342.63204677447646, 65.99448662991679, 0.002145368884157506],
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
        { clip: [0.5, 0, 0], 'local-minde': [3.4921217446, 11.2665189221, 0] }
      ]
    ]
  }
}.freeze

COLOR_SPACES.each_value do |value|
  value.each_key do |key|
    if key == :constructor
      value.define_singleton_method(key) do |*args|
        ColorConstructors.send(value[key], *args)
      end
    else
      value.define_singleton_method(key) do
        value[key]
      end
    end
  end
end
