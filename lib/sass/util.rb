# frozen_string_literal: true

module Sass
  # Utilities functions
  module Util
    module_function

    FILE_PROTOCOL = 'file://'

    def file_uri(path)
      absolute_path = File.absolute_path(path)

      unless absolute_path.start_with? File::SEPARATOR
        components = absolute_path.split File::SEPARATOR
        components[0] = components[0][0].downcase
        absolute_path = components.join File::SEPARATOR
      end

      "#{FILE_PROTOCOL}#{absolute_path}"
    end

    def path(file_uri)
      absolute_path = file_uri[FILE_PROTOCOL.length..]

      unless absolute_path.start_with? File::SEPARATOR
        components = absolute_path.split File::SEPARATOR
        components[0] = "#{components[0].upcase}:"
        absolute_path = components.join File::SEPARATOR
      end

      absolute_path
    end

    def relative(from, to)
      Pathname.new(File.absolute_path(to)).relative_path_from(Pathname.new(File.absolute_path(from))).to_s
    end

    def now
      (Time.now.to_f * 1000).to_i
    end
  end
end
