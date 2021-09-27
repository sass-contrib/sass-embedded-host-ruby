# frozen_string_literal: true

require_relative 'platform'

module Sass
  class Embedded
    module Compiler
      PATH = File.absolute_path(
        "../../../ext/sass/sass_embedded/dart-sass-embedded#{Platform::OS == 'windows' ? '.bat' : ''}", __dir__
      )

      PROTOCOL_ERROR_ID = 4_294_967_295

      REQUIREMENTS = '~> 1.0.0-beta.11'
    end
  end
end
