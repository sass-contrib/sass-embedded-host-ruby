# frozen_string_literal: true

module Sass
  class Embedded
    # The {Host} class.
    #
    # It communicates with {Dispatcher} and handles the host logic.
    class Host
      def initialize(channel)
        @channel = channel
      end

      def id
        @connection.id
      end

      def send_message(message)
        @connection.send_message(message)
      end

      def compile_request(path:,
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
        await do
          @function_registry = FunctionRegistry.new(functions, alert_color: alert_color)
          @importer_registry = ImporterRegistry.new(importers, load_paths, alert_color: alert_color)
          @logger_registry = LoggerRegistry.new(logger)

          send_message EmbeddedProtocol::InboundMessage.new(
            compile_request: EmbeddedProtocol::InboundMessage::CompileRequest.new(
              id: id,
              string: unless source.nil?
                        EmbeddedProtocol::InboundMessage::CompileRequest::StringInput.new(
                          source: source,
                          url: url&.to_s,
                          syntax: Protofier.to_proto_syntax(syntax),
                          importer: importer.nil? ? nil : @importer_registry.register(importer)
                        )
                      end,
              path: path,
              style: Protofier.to_proto_output_style(style),
              source_map: source_map,
              source_map_include_sources: source_map_include_sources,
              importers: @importer_registry.importers,
              global_functions: @function_registry.global_functions,
              alert_ascii: alert_ascii,
              alert_color: alert_color,
              quiet_deps: quiet_deps,
              verbose: verbose
            )
          )
        end
      end

      def version_request
        await do
          send_message EmbeddedProtocol::InboundMessage.new(
            version_request: EmbeddedProtocol::InboundMessage::VersionRequest.new(
              id: id
            )
          )
        end
      end

      def log_event(message)
        @logger_registry.log(message)
      end

      def compile_response(message)
        @async.resolve(message)
      end

      def version_response(message)
        @async.resolve(message)
      end

      def canonicalize_request(message)
        send_message EmbeddedProtocol::InboundMessage.new(
          canonicalize_response: @importer_registry.canonicalize(message)
        )
      end

      def import_request(message)
        send_message EmbeddedProtocol::InboundMessage.new(
          import_response: @importer_registry.import(message)
        )
      end

      def file_import_request(message)
        send_message EmbeddedProtocol::InboundMessage.new(
          file_import_response: @importer_registry.file_import(message)
        )
      end

      def function_call_request(message)
        send_message EmbeddedProtocol::InboundMessage.new(
          function_call_response: @function_registry.function_call(message)
        )
      end

      def error(message)
        @async.reject(CompileError.new(message.message, nil, nil, nil))
      end

      private

      def await
        raise EOFError unless @async.nil?

        @connection = @channel.connect(self)
        @async = Async.new
        yield
        @async.await
      ensure
        @connection.disconnect
      end
    end

    private_constant :Host
  end
end
