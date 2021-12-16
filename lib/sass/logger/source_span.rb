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

      def self.from_proto(source_span)
        return nil if source_span.nil?

        SourceSpan.new(SourceLocation.from_proto(source_span.start),
                       SourceLocation.from_proto(source_span.end),
                       source_span.text,
                       source_span.url,
                       source_span.context)
      end
    end
  end
end
