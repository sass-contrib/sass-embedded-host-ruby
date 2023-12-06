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

      highlight = $stderr.tty? if highlight.nil?
      if highlight
        +@full_message
      else
        @full_message.gsub(/\e\[[0-9;]*m/, '')
      end
    end

    # @return [String]
    def to_css_string
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
          content: #{serialize_quoted_string(message)};
        }
      CSS
    end

    private

    def serialize_quoted_string(string, force_double_quote: false)
      include_single_quote = false
      include_double_quote = false

      buffer = [0]
      string.each_codepoint do |codepoint|
        case codepoint
        when 34
          case
          when force_double_quote
            buffer << 92 << 34
          when include_single_quote
            return serialize_quoted_string(string, force_double_quote: true)
          else
            include_double_quote = true
            buffer << 34
          end
        when 39
          case
          when force_double_quote
            buffer << 39
          when include_double_quote
            return serialize_quoted_string(string, force_double_quote: true)
          else
            include_single_quote = true
            buffer << 39
          end
        when 92
          buffer << 92 << 92
        else
          if (codepoint < 32 && codepoint != 9) || codepoint > 126
            buffer << 92
            buffer.concat(codepoint.to_s(16).codepoints)
            buffer << 32
          else
            buffer << codepoint
          end
        end
      end
      buffer[0] = force_double_quote || !include_double_quote ? 34 : 39
      buffer << buffer[0]
      buffer.pack('U*')
    end
  end
end
