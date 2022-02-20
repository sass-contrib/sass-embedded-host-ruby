# frozen_string_literal: true

module Sass
  # The {CompileResult} of {Embedded#compile} or {Embedded#compile_string}.
  class CompileResult
    attr_reader :css, :source_map, :loaded_urls

    def initialize(css, source_map, loaded_urls)
      @css = css
      @source_map = source_map == '' ? nil : source_map
      @loaded_urls = loaded_urls
    end
  end
end
