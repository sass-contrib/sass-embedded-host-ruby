# frozen_string_literal: true

module Sass
  class Compiler
    class Session
      # @see https://pub.dev/documentation/path/latest/path/
      module Path
        module_function

        # @see https://pub.dev/documentation/path/latest/path/Context/prettyUri.html
        def pretty_uri(uri)
          return uri unless uri&.start_with?('file:')

          absolute_path = Uri.file_uri_to_path(uri)
          relative_path = Uri.decode_uri_component(Uri.relative(uri, Uri.pwd))
          relative_path.count('/') > absolute_path.count('/') ? absolute_path : relative_path
        end

        def pretty_formatted!(formatted, uri)
          index = formatted.index(uri)
          return formatted unless index

          replacement = pretty_uri(uri)
          return formatted if uri == replacement

          formatted[index, uri.length] = replacement
          formatted
        end
      end

      private_constant :Path
    end
  end
end
