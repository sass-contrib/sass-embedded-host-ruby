# frozen_string_literal: true

module Sass
  # The interface for using dart-sass-embedded
  class Embedded
    def initialize
      @transport = Transport.new
      @id_semaphore = Mutex.new
      @id = 0
    end

    def info
      @transport.send EmbeddedProtocol::InboundMessage::VersionRequest.new(
        id: next_id
      )
    end

    def render(data: nil,
               file: nil,
               indented_syntax: false,
               include_paths: [],
               output_style: :expanded,
               precision: 5,
               indent_type: :space,
               indent_width: 2,
               linefeed: :lf,
               source_comments: false,
               source_map: false,
               out_file: nil,
               omit_source_map_url: false,
               source_map_contents: false,
               source_map_embed: false,
               source_map_root: '',
               functions: {},
               importer: [])
      raise NotImplementedError, 'precision is not implemented' if precision != 5
      raise NotImplementedError, 'source_comments is not implemented' if source_comments == true
      raise NotImplementedError, 'omit_source_map_url is not implemented' if omit_source_map_url == true
      raise NotImplementedError, 'source_map_contents is not implemented' if source_map_contents == true
      raise NotImplementedError, 'source_map_embed is not implemented' if source_map_embed == true
      raise NotImplementedError, 'source_map_root is not implemented' if source_map_root != ''

      indent = parse_indent(indent_type, indent_width)
      linefeed = parse_linefeed(linefeed)

      start = Util.now

      compilation_id = next_id

      renderer = Renderer.new(
        data: data,
        file: file,
        indented_syntax: indented_syntax,
        include_paths: include_paths,
        output_style: output_style,
        source_map: source_map,
        out_file: out_file,
        functions: functions,
        importer: importer
      )

      response = @transport.send renderer.compile_request(compilation_id), compilation_id

      loop do
        case response
        when EmbeddedProtocol::OutboundMessage::CompileResponse
          break
        when EmbeddedProtocol::OutboundMessage::CanonicalizeRequest
          response = @transport.send renderer.canonicalize_response(response), compilation_id
        when EmbeddedProtocol::OutboundMessage::ImportRequest
          response = @transport.send renderer.import_response(response), compilation_id
        when EmbeddedProtocol::OutboundMessage::FunctionCallRequest
          response = @transport.send renderer.function_call_response(response), compilation_id
        when EmbeddedProtocol::ProtocolError
          raise ProtocolError, response.message
        else
          raise ProtocolError, "Unexpected packet received: #{response}"
        end
      end

      if response.failure
        raise RenderError.new(
          response.failure.message,
          response.failure.formatted,
          if response.failure.span
            response.failure.span.url == '' ? 'stdin' : URI.parse(response.failure.span.url).path
          end,
          response.failure.span ? response.failure.span.start.line + 1 : nil,
          response.failure.span ? response.failure.span.start.column + 1 : nil,
          1
        )
      end

      css = +response.success.css

      if indent_width != 2 || indent_type.to_sym != :space
        css.gsub!(/^ +/) do |space|
          indent * (space.length / 2)
        end
      end

      css.gsub!("\n", linefeed) if linefeed != "\n"

      finish = Util.now

      {
        css: -css,
        map: response.success.source_map,
        stats: {
          entry: file.nil? ? 'data' : file,
          start: start,
          end: finish,
          duration: finish - start
        }
      }
    end

    def close
      @transport.close
      nil
    end

    private

    def parse_indent(indent_type, indent_width)
      raise RangeError, 'indent_width must be integer in between between 0 and 10 (inclusive)' unless indent_width.is_a?(Integer) && indent_width.between?(0, 10)

      case indent_type.to_sym
      when :space
        ' ' * indent_width
      when :tab
        "\t" * indent_width
      else
        raise ArgumentError, 'indent_type must be :space or :tab'
      end
    end

    def parse_linefeed(linefeed)
      case linefeed.to_sym
      when :lf
        "\n"
      when :lfcr
        "\n\r"
      when :cr
        "\r"
      when :crlf
        "\r\n"
      else
        raise ArgumentError, 'linefeed must be one of :lf, :lfcr, :cr, :crlf'
      end
    end

    def next_id
      @id_semaphore.synchronize do
        @id += 1
        @id = 0 if @id == Transport::PROTOCOL_ERROR_ID
        @id
      end
    end

    # Helper class that maintains render state
    class Renderer
      def initialize(data:,
                     file:,
                     indented_syntax:,
                     include_paths:,
                     output_style:,
                     source_map:,
                     out_file:,
                     functions:,
                     importer:)
        raise ArgumentError, 'either data or file must be set' if file.nil? && data.nil?

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
      end

      def compile_request(id)
        EmbeddedProtocol::InboundMessage::CompileRequest.new(
          id: id,
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
        url = Util.file_uri(File.absolute_path(canonicalize_request.url, (@file.nil? ? 'stdin' : @file)))

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
          canonicalized_url = Util.file_uri(result[:file])

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
        EmbeddedProtocol::InboundMessage::FunctionCallResponse.new(
          id: function_call_request.id,
          success: @functions[function_call_request.name].call(*function_call_request.arguments)
        )
      rescue StandardError => e
        EmbeddedProtocol::InboundMessage::FunctionCallResponse.new(
          id: function_call_request.id,
          error: e.message
        )
      end

      private

      def syntax
        if @indented_syntax == true
          EmbeddedProtocol::Syntax::INDENTED
        else
          EmbeddedProtocol::Syntax::SCSS
        end
      end

      def url
        return if @file.nil?

        Util.file_uri(@file)
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
        case @output_style.to_sym
        when :expanded
          EmbeddedProtocol::OutputStyle::EXPANDED
        when :compressed
          EmbeddedProtocol::OutputStyle::COMPRESSED
        when :nested, :compact
          raise ArgumentError, "#{@output_style} is not a supported output_style"
        else
          raise ArgumentError, "#{@output_style} is not a valid utput_style"
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
      # 5. Each load path specified in the SASS_PATH environment variable, which should be semicolon-separated on Windows and colon-separated elsewhere.
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
