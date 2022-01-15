# frozen_string_literal: true

require 'uri'

module Sass
  class Embedded
    # The {Url} module.
    module Url
      # The {::URI::Parser} that is in consistent with Dart Uri.
      URI_PARSER = URI::Parser.new({ RESERVED: ';/?:@&=+$,' })

      private_constant :URI_PARSER

      module_function

      def path_to_file_url(path)
        "file://#{Platform::OS == 'windows' ? File::SEPARATOR : ''}#{URI_PARSER.escape(path)}"
      end

      def file_url_to_path(file_uri)
        URI_PARSER.unescape(file_uri[(Platform::OS == 'windows' ? 8 : 7)..])
      end
    end
  end
end
