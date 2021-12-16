# frozen_string_literal: true

module Sass
  # The {ImporterResult} of {Importer#load}.
  class ImporterResult
    attr_reader :contents, :syntax, :source_map_url

    def initialize(contents, syntax, source_map_url = nil)
      @contents = contents
      @syntax = syntax
      @source_map_url = source_map_url
    end
  end
end
