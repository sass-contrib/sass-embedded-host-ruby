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
        @function_registery = FunctionRegistry.new(functions.transform_keys(&:to_s))
        @importer_registery = ImporterRegistry.new(importers.map do |obj|
          Protofier.to_struct(obj)
        end, load_paths)
        @logger_registery = LoggerRegistry.new(Protofier.to_struct(logger))

        super(channel)

        send_message EmbeddedProtocol::InboundMessage::CompileRequest.new(
          id: id,
          string: unless source.nil?
                    EmbeddedProtocol::InboundMessage::CompileRequest::StringInput.new(
                      source: source,
                      url: url&.to_s,
                      syntax: Protofier.to_proto_syntax(syntax),
                      importer: importer.nil? ? nil : @importer_registery.register(Protofier.to_struct(importer))
                    )
                  end,
          path: path,
          style: Protofier.to_proto_output_style(style),
          source_map: source_map,
          source_map_include_sources: source_map_include_sources,
          importers: @importer_registery.importers,
          global_functions: @function_registery.global_functions,
          alert_ascii: alert_ascii,
          alert_color: alert_color,
          quiet_deps: quiet_deps,
          verbose: verbose
        )
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

          @logger_registery.log message
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
    end

    private_constant :CompileContext
  end
end
