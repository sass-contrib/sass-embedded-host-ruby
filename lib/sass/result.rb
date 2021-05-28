# frozen_string_literal: true

module Sass
  # The {Result} of {Embedded#render}.
  class Result
    include Struct

    attr_reader :css, :map, :stats

    def initialize(css, map, stats)
      @css = css
      @map = map
      @stats = stats
    end

    # The {Stats} of {Embedded#render}.
    class Stats
      include Struct

      attr_reader :entry, :start, :end, :duration

      def initialize(entry, start, finish, duration)
        @entry = entry
        @start = start
        @end = finish
        @duration = duration
      end
    end
  end
end
