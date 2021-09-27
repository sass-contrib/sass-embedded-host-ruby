# frozen_string_literal: true

require_relative '../platform'

module Sass
  class Embedded
    class Compiler
      PATH = File.absolute_path(
        "../../../../ext/sass/sass_embedded/dart-sass-embedded#{Platform::OS == 'windows' ? '.bat' : ''}", __dir__
      )
    end
  end
end
