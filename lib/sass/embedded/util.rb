# frozen_string_literal: true

require 'pathname'
require 'uri'

module Sass
  class Embedded
    # The {Util} module.
    module Util
      URI_PARSER = URI::Parser.new({ RESERVED: ';/?:@&=+$,' })

      private_constant :URI_PARSER

      module_function

      def file_uri_from_path(path)
        "file://#{Platform::OS == 'windows' ? File::SEPARATOR : ''}#{URI_PARSER.escape(path)}"
      end

      def path_from_file_uri(file_uri)
        URI_PARSER.unescape(file_uri[(Platform::OS == 'windows' ? 8 : 7)..])
      end
    end
  end
end
