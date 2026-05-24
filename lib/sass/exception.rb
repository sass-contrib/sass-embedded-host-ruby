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

    if Exception.public_method_defined?(:detailed_message, false)
      # @!visibility private
      def initialize(message, detailed_message, sass_stack, span, loaded_urls)
        super(message)

        @detailed_message = detailed_message
        @sass_stack = sass_stack
        @span = span
        @loaded_urls = loaded_urls
      end

      # @!visibility private
      def detailed_message(highlight: nil, **)
        return super if @detailed_message.nil?

        highlight = Exception.to_tty? if highlight.nil?

        detailed_message = @detailed_message.sub(message, super)
        detailed_message.gsub!(/\e\[[0-9;]*m/, '') unless highlight
        detailed_message
      end
    else # TODO: remove once ruby 3.1 support is dropped
      # @!visibility private
      def initialize(message, detailed_message, sass_stack, span, loaded_urls)
        super(detailed_message.nil? ? message : detailed_message)

        @message = message
        @detailed_message = detailed_message
        @sass_stack = sass_stack
        @span = span
        @loaded_urls = loaded_urls
      end

      # @!visibility private
      def message
        return @message if @detailed_message.nil? || @full_message.nil?

        @detailed_message
      end

      # @!visibility private
      def detailed_message(highlight: nil, **)
        highlight = Exception.to_tty? if highlight.nil?

        super_ = if highlight
                   lines = message.split("\n")
                   lines[0] += " (\e[1;4m#{self.class.name}\e[m\e[1m)" unless lines.empty?
                   lines.map { |line| "\e[1m#{line}\e[m" }.join("\n")
                 else
                   lines = message.split("\n", 2)
                   lines[0] += " (#{self.class.name})" unless lines.empty?
                   lines.join("\n")
                 end

        return super_ if @detailed_message.nil?

        detailed_message = @detailed_message.sub(message, super_)
        detailed_message.gsub!(/\e\[[0-9;]*m/, '') unless highlight
        detailed_message
      end

      # @!visibility private
      def full_message(highlight: nil, order: :top, **)
        highlight = Exception.to_tty? if highlight.nil?

        @full_message = true
        full_message = super.force_encoding(message.encoding)
        full_message.gsub!(/\e\[[0-9;]*m/, '') unless highlight
        full_message
      ensure
        @full_message = nil
      end
    end

    # @return [String]
    def to_css
      content = full_message(highlight: false, order: :top)

      <<~CSS.freeze
        /* #{content.gsub('*/', "*\u2060/").gsub("\r\n", "\n").split("\n").join("\n * ")} */

        body::before {
          position: static;
          display: block;
          padding: 1em;
          margin: 0 0 1em;
          border-width: 0 0 2px;
          border-bottom-style: solid;
          font-family: monospace, monospace;
          white-space: pre;
          content: #{Serializer.serialize_quoted_string(content).gsub(/[^[:ascii:]][\h\t ]?/) do |match|
            ordinal = match.ord
            replacement = "\\#{ordinal.to_s(16)}"
            if match.length > 1
              replacement << ' ' if ordinal < 0x100000
              replacement << match[1]
            end
            replacement
          end};
        }
      CSS
    end
  end

  # An exception thrown by Sass Script.
  class ScriptError < StandardError
    # @!visibility private
    def initialize(message, name = nil)
      super(name.nil? ? message : "$#{name}: #{message}")
    end
  end
end
