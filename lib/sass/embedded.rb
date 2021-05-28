# frozen_string_literal: true

require 'json'
require 'base64'

module Sass
  # The interface for using dart-sass-embedded
  class Embedded
    def initialize
      @transport = Transport.new
      @id_semaphore = Mutex.new
      @id = 0
    end

    def info
      @info ||= InfoContext.new(@transport, next_id).fetch
    end

    def render(data: nil,
               file: nil,
               indented_syntax: false,
               include_paths: [],
               output_style: :expanded,
               # precision: 5,
               indent_type: :space,
               indent_width: 2,
               linefeed: :lf,
               # source_comments: false,
               source_map: false,
               out_file: nil,
               omit_source_map_url: false,
               # source_map_contents: false,
               source_map_embed: false,
               source_map_root: '',
               functions: {},
               importer: [])
      start = Util.now

      indent_type = parse_indent_type(indent_type)
      indent_width = parse_indent_width(indent_width)
      linefeed = parse_linefeed(linefeed)

      response = RenderContext.new(@transport, next_id,
                                   data: data,
                                   file: file,
                                   indented_syntax: indented_syntax,
                                   include_paths: include_paths,
                                   output_style: output_style,
                                   source_map: source_map,
                                   out_file: out_file,
                                   functions: functions,
                                   importer: importer).fetch

      if response.failure
        raise RenderError.new(
          response.failure.message,
          response.failure.formatted,
          if response.failure.span.nil?
            nil
          elsif response.failure.span.url == ''
            'stdin'
          else
            Util.path(response.failure.span.url)
          end,
          response.failure.span ? response.failure.span.start.line + 1 : nil,
          response.failure.span ? response.failure.span.start.column + 1 : nil,
          1
        )
      end

      map, source_map = post_process_map(map: response.success.source_map,
                                         file: file,
                                         out_file: out_file,
                                         source_map: source_map,
                                         source_map_root: source_map_root)

      css = post_process_css(css: response.success.css,
                             indent_type: indent_type,
                             indent_width: indent_width,
                             linefeed: linefeed,
                             map: map,
                             out_file: out_file,
                             omit_source_map_url: omit_source_map_url,
                             source_map: source_map,
                             source_map_embed: source_map_embed)

      finish = Util.now

      {
        css: css,
        map: map,
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
    end

    def closed?
      @transport.closed?
    end

    private

    def post_process_map(map:,
                         file:,
                         out_file:,
                         source_map:,
                         source_map_root:)
      return if map.nil? || map.empty?

      map_data = JSON.parse(map)

      map_data['sourceRoot'] = source_map_root

      source_map_path = if source_map.is_a? String
                          source_map
                        else
                          "#{out_file}.map"
                        end

      source_map_dir = File.dirname(source_map_path)

      if out_file
        map_data['file'] = Util.relative(source_map_dir, out_file)
      elsif file
        ext = File.extname(file)
        map_data['file'] = "#{file[0..(ext.empty? ? -1 : -ext.length - 1)]}.css"
      else
        map_data['file'] = 'stdin.css'
      end

      map_data['sources'].map! do |source|
        if source.start_with? Util::FILE_PROTOCOL
          Util.relative(source_map_dir, Util.path(source))
        else
          source
        end
      end

      [-JSON.generate(map_data), source_map_path]
    end

    def post_process_css(css:,
                         indent_type:,
                         indent_width:,
                         linefeed:,
                         map:,
                         omit_source_map_url:,
                         out_file:,
                         source_map:,
                         source_map_embed:)
      css = +css
      if indent_width != 2 || indent_type.to_sym != :space
        indent = indent_type * indent_width
        css.gsub!(/^ +/) do |space|
          indent * (space.length / 2)
        end
      end
      css.gsub!("\n", linefeed) if linefeed != "\n"

      unless map.nil? || omit_source_map_url == true
        url = if source_map_embed
                "data:application/json;base64,#{Base64.strict_encode64(map)}"
              elsif out_file
                Util.relative(File.dirname(out_file), source_map)
              else
                source_map
              end
        css += "#{linefeed}/*# sourceMappingURL=#{url} */"
      end

      -css
    end

    def parse_indent_type(indent_type)
      case indent_type.to_sym
      when :space
        ' '
      when :tab
        "\t"
      else
        raise ArgumentError, 'indent_type must be one of :space, :tab'
      end
    end

    def parse_indent_width(indent_width)
      raise ArgumentError, 'indent_width must be an integer' unless indent_width.is_a? Integer
      raise RangeError, 'indent_width must be in between 0 and 10 (inclusive)' unless indent_width.between? 0, 10

      indent_width
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

    # InfoContext
    class InfoContext < Context
      def initialize(transport, id)
        super(transport, id)
        @transport.send EmbeddedProtocol::InboundMessage::VersionRequest.new(id: @id)
      end

      def update(error, response)
        raise error unless error.nil?

        case response
        when EmbeddedProtocol::ProtocolError
          raise ProtocolError, response.message
        when EmbeddedProtocol::OutboundMessage::VersionResponse
          return unless response.id == @id

          Thread.new do
            super(nil, response)
          end
        end
      rescue StandardError => e
        Thread.new do
          super(e, nil)
        end
      end
    end

    # RenderContext
    class RenderContext < Context
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

        super(transport, id)

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

        @transport.send compile_request
      end

      def update(error, response)
        raise error unless error.nil?

        case response
        when EmbeddedProtocol::ProtocolError
          raise ProtocolError, response.message
        when EmbeddedProtocol::OutboundMessage::CompileResponse
          return unless response.id == @id

          Thread.new do
            super(nil, response)
          end
        when EmbeddedProtocol::OutboundMessage::LogEvent
          # not implemented yet
        when EmbeddedProtocol::OutboundMessage::CanonicalizeRequest
          return unless response['compilation_id'] == @id

          Thread.new do
            @transport.send canonicalize_response(response)
          end
        when EmbeddedProtocol::OutboundMessage::ImportRequest
          return unless response['compilation_id'] == @id

          Thread.new do
            @transport.send import_response(response)
          end
        when EmbeddedProtocol::OutboundMessage::FileImportRequest
          raise NotImplementedError, 'FileImportRequest is not implemented'
        when EmbeddedProtocol::OutboundMessage::FunctionCallRequest
          return unless response['compilation_id'] == @id

          Thread.new do
            @transport.send function_call_response(response)
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

      def syntax
        if @indented_syntax == true
          EmbeddedProtocol::Syntax::INDENTED
        else
          EmbeddedProtocol::Syntax::SCSS
        end
      end

      def url
        return if @file.nil?

        Util.file_uri @file
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
