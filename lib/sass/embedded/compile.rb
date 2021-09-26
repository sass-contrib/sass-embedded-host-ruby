# frozen_string_literal: true

require_relative 'observer'
require_relative 'protocol'
require_relative 'util'

module Sass
  class Embedded
    # The {Observer} for {Embedded#render}.
    class CompileContext
      include Observer

      def initialize(transport, id,
                     data:,
                     file:,
                     indented_syntax:,
                     include_paths:,
                     output_style:,
                     source_map:,
                     out_file:,
                     functions:,
                     importer:)
        raise ArgumentError, 'either data or file must be set' if file.nil? && data.nil?

        @id = id
        @data = data
        @file = file
        @indented_syntax = indented_syntax
        @include_paths = include_paths
        @output_style = output_style
        @source_map = source_map
        @out_file = out_file
        @global_functions = functions.keys
        @functions = functions.transform_keys do |key|
          key.to_s.split('(')[0].chomp
        end
        @importer = importer
        @import_responses = {}

        super(transport)

        send_message compile_request
      end

      def update(error, message)
        raise error unless error.nil?

        case message
        when EmbeddedProtocol::OutboundMessage::CompileResponse
          return unless message.id == @id

          Thread.new do
            super(nil, message)
          end
        when EmbeddedProtocol::OutboundMessage::LogEvent
          return unless message.compilation_id == @id && $stderr.tty?

          warn message.formatted
        when EmbeddedProtocol::OutboundMessage::CanonicalizeRequest
          return unless message.compilation_id == @id

          Thread.new do
            send_message canonicalize_response message
          end
        when EmbeddedProtocol::OutboundMessage::ImportRequest
          return unless message.compilation_id == @id

          Thread.new do
            send_message import_response message
          end
        when EmbeddedProtocol::OutboundMessage::FileImportRequest
          raise NotImplementedError, 'FileImportRequest is not implemented'
        when EmbeddedProtocol::OutboundMessage::FunctionCallRequest
          return unless message.compilation_id == @id

          Thread.new do
            send_message function_call_response message
          end
        end
      rescue StandardError => e
        Thread.new do
          super(e, nil)
        end
      end

      private

      def compile_request
        EmbeddedProtocol::InboundMessage::CompileRequest.new(
          id: @id,
          string: string,
          path: path,
          style: style,
          source_map: source_map,
          importers: importers,
          global_functions: global_functions,
          alert_color: $stderr.tty?,
          alert_ascii: Platform::OS == 'windows'
        )
      end

      def canonicalize_response(canonicalize_request)
        url = Util.file_uri_from_path(File.absolute_path(canonicalize_request.url, (@file.nil? ? 'stdin' : @file)))

        begin
          result = @importer[canonicalize_request.importer_id].call canonicalize_request.url, @file
          raise result if result.is_a? StandardError
        rescue StandardError => e
          return EmbeddedProtocol::InboundMessage::CanonicalizeResponse.new(
            id: canonicalize_request.id,
            error: e.message
          )
        end

        if result&.key? :contents
          @import_responses[url] = EmbeddedProtocol::InboundMessage::ImportResponse.new(
            id: canonicalize_request.id,
            success: EmbeddedProtocol::InboundMessage::ImportResponse::ImportSuccess.new(
              contents: result[:contents],
              syntax: EmbeddedProtocol::Syntax::SCSS,
              source_map_url: nil
            )
          )
          EmbeddedProtocol::InboundMessage::CanonicalizeResponse.new(
            id: canonicalize_request.id,
            url: url
          )
        elsif result&.key? :file
          canonicalized_url = Util.file_uri_from_path(File.absolute_path(result[:file]))

          # TODO: FileImportRequest is not supported yet.
          # Workaround by reading contents and return it when server asks
          @import_responses[canonicalized_url] = EmbeddedProtocol::InboundMessage::ImportResponse.new(
            id: canonicalize_request.id,
            success: EmbeddedProtocol::InboundMessage::ImportResponse::ImportSuccess.new(
              contents: File.read(result[:file]),
              syntax: EmbeddedProtocol::Syntax::SCSS,
              source_map_url: nil
            )
          )

          EmbeddedProtocol::InboundMessage::CanonicalizeResponse.new(
            id: canonicalize_request.id,
            url: canonicalized_url
          )
        else
          EmbeddedProtocol::InboundMessage::CanonicalizeResponse.new(
            id: canonicalize_request.id
          )
        end
      end

      def import_response(import_request)
        url = import_request.url

        if @import_responses.key? url
          @import_responses[url].id = import_request.id
        else
          @import_responses[url] = EmbeddedProtocol::InboundMessage::ImportResponse.new(
            id: import_request.id,
            error: "Failed to import: #{url}"
          )
        end

        @import_responses[url]
      end

      def function_call_response(function_call_request)
        # TODO: convert argument_list to **kwargs
        EmbeddedProtocol::InboundMessage::FunctionCallResponse.new(
          id: function_call_request.id,
          success: @functions[function_call_request.name].call(*function_call_request.arguments),
          accessed_argument_lists: function_call_request.arguments
            .filter { |argument| argument.value == :argument_list }
            .map { |argument| argument.argument_list.id }
        )
      rescue StandardError => e
        EmbeddedProtocol::InboundMessage::FunctionCallResponse.new(
          id: function_call_request.id,
          error: e.message
        )
      end

      def syntax
        if @indented_syntax == true
          EmbeddedProtocol::Syntax::INDENTED
        else
          EmbeddedProtocol::Syntax::SCSS
        end
      end

      def url
        return if @file.nil?

        Util.file_uri_from_path File.absolute_path @file
      end

      def string
        return if @data.nil?

        EmbeddedProtocol::InboundMessage::CompileRequest::StringInput.new(
          source: @data,
          url: url,
          syntax: syntax
        )
      end

      def path
        @file if @data.nil?
      end

      def style
        case @output_style&.to_sym
        when :expanded
          EmbeddedProtocol::OutputStyle::EXPANDED
        when :compressed
          EmbeddedProtocol::OutputStyle::COMPRESSED
        else
          raise ArgumentError, 'output_style must be one of :expanded, :compressed'
        end
      end

      def source_map
        @source_map.is_a?(String) || (@source_map == true && !@out_file.nil?)
      end

      attr_reader :global_functions

      # Order
      # 1. Loading a file relative to the file in which the @use or @import appeared.
      # 2. Each custom importer.
      # 3. Loading a file relative to the current working directory.
      # 4. Each load path in includePaths
      # 5. Each load path specified in the SASS_PATH environment variable, which should
      #    be semicolon-separated on Windows and colon-separated elsewhere.
      def importers
        custom_importers = @importer.map.with_index do |_, id|
          EmbeddedProtocol::InboundMessage::CompileRequest::Importer.new(
            importer_id: id
          )
        end

        include_path_importers = @include_paths
                                 .concat(Sass.include_paths)
                                 .map do |include_path|
          EmbeddedProtocol::InboundMessage::CompileRequest::Importer.new(
            path: File.absolute_path(include_path)
          )
        end

        custom_importers.concat include_path_importers
      end
    end
  end
end
