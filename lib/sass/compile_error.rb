# frozen_string_literal: true

module Sass
  # An exception thrown because a Sass compilation failed.
  class CompileError < StandardError
    # @return [String, nil]
    attr_reader :sass_stack

    # @return [Logger::SourceSpan, nil]
    attr_reader :span

    # @return [Array<String>]
    attr_reader :loaded_urls

    # @!visibility private
    def initialize(message, full_message, sass_stack, span, loaded_urls)
      super(message)

      @full_message = full_message
      @sass_stack = sass_stack
      @span = span
      @loaded_urls = loaded_urls
    end

    # @return [String]
    def full_message(highlight: nil, **)
      return super if @full_message.nil?

      highlight = Exception.to_tty? if highlight.nil?
      if highlight
        +@full_message
      else
        @full_message.gsub(/\e\[[0-9;]*m/, '')
      end
    end

    # @return [String]
    def to_css
      message = full_message(highlight: false, order: :top)

      <<~CSS
        /* #{message.gsub('*/', "*\u2060/").gsub("\r\n", "\n").split("\n").join("\n * ")} */

        body::before {
          display: block;
          padding: 1em;
          margin-bottom: 1em;
          border-bottom: 2px solid;
          font-family: monospace, monospace;
          white-space: pre;
          content: #{Serializer.dump_quoted_string(message)};
        }
      CSS
    end
  end
end
