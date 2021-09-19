# frozen_string_literal: true

require 'pathname'
require 'uri'

module Sass
  # The {Util} module.
  module Util
    module_function

    URI_PARSER = URI::Parser.new({ RESERVED: ';/?:@&=+$,' })

    private_constant :URI_PARSER

    def file_uri_from_path(path)
      "file://#{Platform::OS == 'windows' ? File::SEPARATOR : ''}#{URI_PARSER.escape(path)}"
    end

    def path_from_file_uri(file_uri)
      URI_PARSER.unescape(file_uri[(Platform::OS == 'windows' ? 8 : 7)..])
    end

    def relative_path(from, to)
      Pathname.new(File.absolute_path(to)).relative_path_from(Pathname.new(File.absolute_path(from))).to_s
    end

    def now
      (Time.now.to_f * 1000).to_i
    end
  end
end
