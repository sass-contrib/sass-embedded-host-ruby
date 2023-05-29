# frozen_string_literal: true

module Sass
  class Embedded
    class Host
      # The {LoggerRegistry} class.
      #
      # It stores logger and handles log events.
      class LoggerRegistry
        attr_reader :logger

        def initialize(logger)
          @logger = Structifier.to_struct(logger, :debug, :warn)
        end

        def log(event)
          case event.type
          when :DEBUG
            if logger.respond_to? :debug
              Thread.new do
                logger.debug(event.message,
                             span: Protofier.from_proto_source_span(event.span))
              end
            else
              warn(event.formatted)
            end
          when :DEPRECATION_WARNING
            if logger.respond_to? :warn
              Thread.new do
                logger.warn(event.message,
                            deprecation: true,
                            span: Protofier.from_proto_source_span(event.span),
                            stack: event.stack_trace)
              end
            else
              warn(event.formatted)
            end
          when :WARNING
            if logger.respond_to? :warn
              Thread.new do
                logger.warn(event.message,
                            deprecation: false,
                            span: Protofier.from_proto_source_span(event.span),
                            stack: event.stack_trace)
              end
            else
              warn(event.formatted)
            end
          end
        end
      end

      private_constant :LoggerRegistry
    end
  end
end
