# frozen_string_literal: true

require 'uri'

module Sass
  # The {Uri} class.
  #
  # It follows RFC3986 to match the behavior of Uri class from Dart.
  #
  # @see https://www.rfc-editor.org/info/rfc3986/
  module Uri
    module_function

    def decode_uri_component(str)
      str.b.gsub(/%\h\h/, ::URI::TBLDECWWWCOMP_).force_encoding(str.encoding)
    end

    def encode_uri_component(str)
      str.b.gsub(/[^0-9A-Za-z\-._~]/n, ::URI::TBLENCURICOMP_).force_encoding(str.encoding)
    end

    def encode_uri_path_component(str)
      str.b.gsub(%r{[^0-9A-Za-z\-._~!$&'()*+,;=:@/]}n, ::URI::TBLENCURICOMP_).force_encoding(str.encoding)
    end

    def encode_uri_query_component(str)
      str.b.gsub(%r{[^0-9A-Za-z\-._~!$&'()*+,;=:@/?]}n, ::URI::TBLENCURICOMP_).force_encoding(str.encoding)
    end

    def file_uri_to_path(uri)
      path = decode_uri_component(::URI::RFC3986_PARSER.parse(uri).path)
      if path.start_with?('/')
        windows_path = path[1..]
        path = windows_path if File.absolute_path?(windows_path)
      end
      path
    end

    def path_to_file_uri(path)
      path = "/#{path}" unless path.start_with?('/')
      "file://#{encode_uri_path_component(path)}"
    end

    def pwd
      pwd = Dir.pwd
      pwd += '/' unless pwd.end_with?('/')
      path_to_file_uri(pwd)
    end

    def relative(to, from)
      ::URI::RFC3986_PARSER.parse(to).route_from(from).to_s
    end
  end

  private_constant :Uri
end
