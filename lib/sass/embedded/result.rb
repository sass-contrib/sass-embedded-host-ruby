# frozen_string_literal: true

require_relative 'struct'

module Sass
  class Embedded
    # The {RenderResult} of {Embedded#render}.
    class RenderResult
      include Struct

      attr_reader :css, :map, :stats

      def initialize(css, map, stats)
        @css = css
        @map = map
        @stats = stats
      end
    end

    # The {RenderResultStats} of {Embedded#render}.
    class RenderResultStats
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
