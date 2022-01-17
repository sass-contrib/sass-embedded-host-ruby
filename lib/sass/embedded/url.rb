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
        if File.absolute_path? path
          "file://#{Platform::OS == 'windows' ? File::SEPARATOR : ''}#{URI_PARSER.escape(path)}"
        else
          URI_PARSER.escape(path)
        end
      end

      def file_url_to_path(url)
        if url.start_with? 'file://'
          URI_PARSER.unescape url[(Platform::OS == 'windows' ? 8 : 7)..]
        else
          URI_PARSER.unescape url
        end
      end
    end
  end
end
