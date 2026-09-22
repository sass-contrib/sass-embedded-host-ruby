# frozen_string_literal: true

module Sass
  class Compiler
    class Session
      # The {LoggerRegistry} class.
      class LoggerRegistry
        def initialize(logger, alert_color:)
          if logger.is_a?(::Hash)
            respond_to_debug = logger[:debug].respond_to?(:call)
            respond_to_warn = logger[:warn].respond_to?(:call)
            logger = LoggerStruct.new(logger) if respond_to_debug || respond_to_warn
          else
            respond_to_debug = logger.respond_to?(:debug)
            respond_to_warn = logger.respond_to?(:warn)
          end
          @logger = logger
          @alert_color = alert_color
          @respond_to_debug = respond_to_debug
          @respond_to_warn = respond_to_warn
        end

        def log(event)
          case event.type
          when :DEBUG
            if @respond_to_debug
              @logger.debug(event.message, DebugContext.new(event))
            else
              path = event.span.url == '' ? '-' : Path.pretty_uri(event.span.url)
              line = event.span.start.line + 1
              type = @alert_color ? "\e[1mDebug\e[0m" : 'DEBUG'
              Warning.warn("#{path}:#{line} #{type}: #{event.message}\n")
            end
          when :DEPRECATION_WARNING, :WARNING
            if @respond_to_warn
              @logger.warn(event.message, WarnContext.new(event))
            else
              Warning.warn(StackTrace.pretty_formatted!(+event.formatted, event.stack_trace))
            end
          else
            raise ArgumentError, "Unknown LogEvent.type #{event.type}"
          end
        end

        # Contextual information passed to `debug`.
        class DebugContext
          # @return [Logger::SourceSpan, nil]
          attr_reader :span

          def initialize(event)
            @span = event.span.nil? ? nil : Logger::SourceSpan.new(event.span)
          end
        end

        private_constant :DebugContext

        # Contextual information passed to `warn`.
        class WarnContext < DebugContext
          # @return [Boolean]
          attr_reader :deprecation

          # @return [String, nil]
          attr_reader :deprecation_type

          # @return [String]
          attr_reader :stack

          def initialize(event)
            super
            @deprecation = event.type == :DEPRECATION_WARNING
            @deprecation_type = (event.deprecation_type if @deprecation)
            @stack = event.stack_trace
          end
        end

        private_constant :WarnContext

        # The {LoggerStruct} class.
        class LoggerStruct
          def initialize(hash)
            @hash = hash
          end

          def debug(...)
            @hash[:debug].call(...)
          end

          def warn(...)
            @hash[:warn].call(...)
          end
        end

        private_constant :LoggerStruct
      end

      private_constant :LoggerRegistry
    end
  end
end
