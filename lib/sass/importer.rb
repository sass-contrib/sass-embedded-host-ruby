# frozen_string_literal: true

module Sass
  # The {Importer} interface.
  class Importer
    def canonicalize(url) # rubocop:disable Lint/UnusedMethodArgument
      raise NotImplementedError, 'Importer#canonicalize must be implemented'
    end

    def load(canonical_url) # rubocop:disable Lint/UnusedMethodArgument
      raise NotImplementedError, 'Importer#load must be implemented'
    end
  end
end
