# frozen_string_literal: true

module Sass
  # Utilities functions
  module Util
    module_function

    def file_uri(path)
      absolute_path = File.absolute_path(path)

      unless absolute_path.start_with?('/')
        components = absolute_path.split File::SEPARATOR
        components[0] = components[0].split(':').first.downcase
        absolute_path = components.join File::SEPARATOR
      end

      "file://#{absolute_path}"
    end

    def now
      (Time.now.to_f * 1000).to_i
    end
  end
end
