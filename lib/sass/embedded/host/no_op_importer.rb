# frozen_string_literal: true

module Sass
  class Embedded
    class Host
      # An importer that never imports any stylesheets.
      module NoOpImporter
        module_function

        def canonicalize(*); end
        def load(*); end
      end

      private_constant :NoOpImporter
    end
  end
end
