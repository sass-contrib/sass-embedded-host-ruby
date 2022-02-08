# frozen_string_literal: true

module Sass
  class Embedded
    class Compiler
      PATH = File.absolute_path(
        "../../../../ext/sass/sass_embedded/dart-sass-embedded#{Gem.win_platform? ? '.bat' : ''}", __dir__
      )
    end
  end
end
