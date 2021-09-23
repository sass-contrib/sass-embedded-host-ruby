# frozen_string_literal: true

module Sass
  module Compiler
    DART_SASS_EMBEDDED = File.absolute_path(
      "../../ext/sass/sass_embedded/dart-sass-embedded#{Platform::OS == 'windows' ? '.bat' : ''}", __dir__
    )

    PROTOCOL_ERROR_ID = 4_294_967_295
  end
end
