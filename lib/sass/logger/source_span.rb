# frozen_string_literal: true

require_relative 'source_location'

module Sass
  module Logger
    # The {SourceSpan} in {CompileError}.
    class SourceSpan
      attr_reader :start, :end, :text, :url, :context

      def initialize(start, end_, text, url, context)
        @start = start
        @end = end_
        @text = text
        @url = url == '' ? nil : url
        @context = context == '' ? nil : context
      end
    end
  end
end
