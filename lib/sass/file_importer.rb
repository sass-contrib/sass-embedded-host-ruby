# frozen_string_literal: true

module Sass
  # The {FileImporter} interface.
  class FileImporter
    def find_file_url(url, from_import:) # rubocop:disable Lint/UnusedMethodArgument
      raise NotImplementedError, 'FileImporter#find_file_url must be implemented'
    end
  end
end
