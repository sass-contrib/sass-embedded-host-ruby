# frozen_string_literal: true

module Sass
  class Compiler
    class Session
      # The {LoggerRegistry} module.
      module LoggerRegistry
        def self.new(logger, alert_color:)
          if logger.is_a?(::Hash)
            respond_to_debug = logger[:debug].respond_to?(:call)
            respond_to_warn = logger[:warn].respond_to?(:call)
            if respond_to_debug && respond_to_warn
              DebugWarnEventLoggerStruct
            elsif respond_to_debug
              DebugEventLoggerStruct
            elsif respond_to_warn
              WarnEventLoggerStruct
            else
              EventLogger
            end
          else
            respond_to_debug = logger.respond_to?(:debug)
            respond_to_warn = logger.respond_to?(:warn)
            if respond_to_debug && respond_to_warn
              DebugWarnEventLogger
            elsif respond_to_debug
              DebugEventLogger
            elsif respond_to_warn
              WarnEventLogger
            else
              EventLogger
            end
          end.new(logger, alert_color:)
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

        # The {EventLogger} class.
        class EventLogger
          def initialize(logger, alert_color:)
            @logger = logger
            @alert_color = alert_color
          end

          def debug(event)
            path = event.span.url == '' ? '-' : Path.pretty_uri(event.span.url)
            line = event.span.start.line + 1
            type = @alert_color ? "\e[1mDebug\e[0m" : 'DEBUG'
            Warning.warn("#{path}:#{line} #{type}: #{event.message}\n")
          end

          def warn(event)
            Warning.warn(StackTrace.pretty_formatted!(+event.formatted, event.stack_trace))
          end
        end

        private_constant :EventLogger

        # The {DebugEventLogger} class.
        class DebugEventLogger < EventLogger
          def debug(event)
            @logger.debug(event.message, DebugContext.new(event))
          end
        end

        private_constant :DebugEventLogger

        # The {WarnEventLogger} class.
        class WarnEventLogger < EventLogger
          def warn(event)
            @logger.warn(event.message, WarnContext.new(event))
          end
        end

        private_constant :WarnEventLogger

        # The {DebugWarnEventLogger} class.
        class DebugWarnEventLogger < EventLogger
          def debug(event)
            @logger.debug(event.message, DebugContext.new(event))
          end

          def warn(event)
            @logger.warn(event.message, WarnContext.new(event))
          end
        end

        private_constant :DebugWarnEventLogger

        # The {DebugEventLoggerStruct} class.
        class DebugEventLoggerStruct < EventLogger
          def debug(event)
            @logger[:debug].call(event.message, DebugContext.new(event))
          end
        end

        private_constant :DebugEventLoggerStruct

        # The {WarnEventLoggerStruct} class.
        class WarnEventLoggerStruct < EventLogger
          def warn(event)
            @logger[:warn].call(event.message, WarnContext.new(event))
          end
        end

        private_constant :WarnEventLoggerStruct

        # The {DebugWarnEventLoggerStruct} class.
        class DebugWarnEventLoggerStruct < EventLogger
          def debug(event)
            @logger[:debug].call(event.message, DebugContext.new(event))
          end

          def warn(event)
            @logger[:warn].call(event.message, WarnContext.new(event))
          end
        end

        private_constant :DebugWarnEventLoggerStruct
      end

      private_constant :LoggerRegistry
    end
  end
end
