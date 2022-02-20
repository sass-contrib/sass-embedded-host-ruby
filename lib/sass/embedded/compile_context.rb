# frozen_string_literal: true

module Sass
  class Embedded
    # The {Observer} for {Embedded#compile}.
    class CompileContext
      include Observer

      def initialize(channel,
                     path:,
                     source:,

                     importer:,
                     load_paths:,
                     syntax:,
                     url:,

                     source_map:,
                     source_map_include_sources:,
                     style:,

                     functions:,
                     importers:,

                     alert_ascii:,
                     alert_color:,
                     logger:,
                     quiet_deps:,
                     verbose:)
        @path = path
        @source = source

        @load_paths = load_paths
        @syntax = syntax
        @url = url

        @source_map = source_map
        @source_map_include_sources = source_map_include_sources
        @style = style

        @function_registery = FunctionRegistry.new(functions.transform_keys(&:to_s))
        @importer_registery = ImporterRegistry.new(importers.map do |obj|
          Protofier.to_struct(obj)
        end, load_paths)
        @importer = importer.nil? ? nil : @importer_registery.register(Protofier.to_struct(importer))

        @alert_ascii = alert_ascii
        @alert_color = alert_color

        @logger = Protofier.to_struct(logger)

        @quiet_deps = quiet_deps
        @verbose = verbose

        super(channel)

        send_message compile_request
      end

      def update(error, message)
        raise error unless error.nil?

        case message
        when EmbeddedProtocol::OutboundMessage::CompileResponse
          return unless message.id == id

          Thread.new do
            super(nil, message)
          end
        when EmbeddedProtocol::OutboundMessage::LogEvent
          return unless message.compilation_id == id

          log message
        when EmbeddedProtocol::OutboundMessage::CanonicalizeRequest
          return unless message.compilation_id == id

          Thread.new do
            send_message @importer_registery.canonicalize message
          end
        when EmbeddedProtocol::OutboundMessage::ImportRequest
          return unless message.compilation_id == id

          Thread.new do
            send_message @importer_registery.import message
          end
        when EmbeddedProtocol::OutboundMessage::FileImportRequest
          return unless message.compilation_id == id

          Thread.new do
            send_message @importer_registery.file_import message
          end
        when EmbeddedProtocol::OutboundMessage::FunctionCallRequest
          return unless message.compilation_id == id

          Thread.new do
            send_message @function_registery.function_call message
          end
        end
      rescue StandardError => e
        Thread.new do
          super(e, nil)
        end
      end

      private

      def log(event)
        case event.type
        when :DEBUG
          if @logger.respond_to? :debug
            @logger.debug(event.message, span: Protofier.from_proto_source_span(event.span))
          else
            Kernel.warn(event.formatted)
          end
        when :DEPRECATION_WARNING
          if @logger.respond_to? :warn
            @logger.warn(event.message, deprecation: true,
                                        span: Protofier.from_proto_source_span(event.span),
                                        stack: event.stack_trace)
          else
            Kernel.warn(event.formatted)
          end
        when :WARNING
          if @logger.respond_to? :warn
            @logger.warn(event.message, deprecation: false,
                                        span: Protofier.from_proto_source_span(event.span),
                                        stack: event.stack_trace)
          else
            Kernel.warn(event.formatted)
          end
        end
      end

      def compile_request
        EmbeddedProtocol::InboundMessage::CompileRequest.new(
          id: id,
          string: unless @source.nil?
                    EmbeddedProtocol::InboundMessage::CompileRequest::StringInput.new(
                      source: @source,
                      url: @url&.to_s,
                      syntax: Protofier.to_proto_syntax(@syntax),
                      importer: @importer
                    )
                  end,
          path: @path,
          style: Protofier.to_proto_output_style(@style),
          source_map: @source_map,
          source_map_include_sources: @source_map_include_sources,
          importers: @importer_registery.importers,
          global_functions: @function_registery.global_functions,
          alert_ascii: @alert_ascii,
          alert_color: @alert_color
        )
      end
    end

    private_constant :CompileContext
  end
end
