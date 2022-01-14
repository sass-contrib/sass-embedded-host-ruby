# frozen_string_literal: true

module Sass
  class Embedded
    # @deprecated
    # The {RenderResult} of {Embedded#render}.
    class RenderResult
      attr_reader :css, :map, :stats

      def initialize(css, map, stats)
        @css = css
        @map = map
        @stats = stats
      end
    end

    # @deprecated
    # The {RenderResultStats} of {Embedded#render}.
    class RenderResultStats
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
