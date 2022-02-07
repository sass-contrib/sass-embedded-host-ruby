# frozen_string_literal: true

require 'uri'
require_relative 'platform'

module Sass
  class Embedded
    # The {Url} module.
    module Url
      # The {::URI::Parser} that is in consistent with RFC 2396 (URI Generic Syntax) and dart:core library.
      URI_PARSER = URI::Parser.new({ RESERVED: ';/?:@&=+$,' })

      FILE_SCHEME = 'file://'

      private_constant :URI_PARSER, :FILE_SCHEME

      module_function

      def path_to_file_url(path)
        if File.absolute_path? path
          URI_PARSER.escape "#{FILE_SCHEME}#{Platform::OS == 'windows' ? File::SEPARATOR : ''}#{path}"
        else
          URI_PARSER.escape path
        end
      end

      def file_url_to_path(url)
        if url.start_with? FILE_SCHEME
          URI_PARSER.unescape url[(FILE_SCHEME.length + (Platform::OS == 'windows' ? 1 : 0))..]
        else
          URI_PARSER.unescape url
        end
      end
    end
  end
end
