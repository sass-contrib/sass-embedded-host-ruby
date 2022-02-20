# frozen_string_literal: true

module Sass
  module Logger
    # A span of text within a source file.
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
