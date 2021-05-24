# frozen_string_literal: true

module Sass
  module Embedded
    class Compiler
      def initialize
        @transport = Transport.new
        @id_semaphore = Mutex.new
        @id = 0
      end

      def render(options)
        start = Sass::Util.now

        raise Sass::NotRenderedError, 'Either :data or :file must be set.' if options[:file].nil? && options[:data].nil?

        string = if options[:data]
                   Sass::EmbeddedProtocol::InboundMessage::CompileRequest::StringInput.new(
                     source: options[:data],
                     url: options[:file] ? Sass::Util.file_uri(options[:file]) : 'stdin',
                     syntax: options[:indented_syntax] == true ? Sass::EmbeddedProtocol::Syntax::INDENTED : Sass::EmbeddedProtocol::Syntax::SCSS
                   )
                 end

        path = options[:data] ? nil : options[:file]

        style = case options[:output_style]&.to_sym
                when :expanded, nil
                  Sass::EmbeddedProtocol::OutputStyle::EXPANDED
                when :compressed
                  Sass::EmbeddedProtocol::OutputStyle::COMPRESSED
                when :nested, :compact
                  raise Sass::UnsupportedValue, "#{options[:output_style]} is not a supported :output_style"
                else
                  raise Sass::InvalidStyleError, "#{options[:output_style]} is not a valid :output_style"
                end

        source_map = options[:source_map].is_a?(String) || (options[:source_map] == true && !options[:out_file].nil?)

        # 1. Loading a file relative to the file in which the @use or @import appeared.
        # 2. Each custom importer.
        # 3. Loading a file relative to the current working directory.
        # 4. Each load path in includePaths
        # 5. Each load path specified in the SASS_PATH environment variable, which should be semicolon-separated on Windows and colon-separated elsewhere.
        importers = (if options[:importer]
                       [
                         Sass::EmbeddedProtocol::InboundMessage::CompileRequest::Importer.new(importer_id: 0)
                       ]
                     else
                       []
                     end).concat(
                       (options[:include_paths] || []).concat(Sass.include_paths)
                       .map do |include_path|
                         Sass::EmbeddedProtocol::InboundMessage::CompileRequest::Importer.new(
                           path: File.absolute_path(include_path)
                         )
                       end
                     )

        signatures = []
        functions = {}
        options[:functions]&.each do |signature, function|
          signatures.push signature
          functions[signature.to_s.split('(')[0].chomp] = function
        end

        compilation_id = next_id

        compile_request = Sass::EmbeddedProtocol::InboundMessage::CompileRequest.new(
          id: compilation_id,
          string: string,
          path: path,
          style: style,
          source_map: source_map,
          importers: importers,
          global_functions: options[:functions] ? signatures : [],
          alert_color: true,
          alert_ascii: true
        )

        response = @transport.send compile_request, compilation_id

        file = options[:file] || 'stdin'
        canonicalizations = {}
        imports = {}

        loop do
          case response
          when Sass::EmbeddedProtocol::OutboundMessage::CompileResponse
            break
          when Sass::EmbeddedProtocol::OutboundMessage::CanonicalizeRequest
            url = Sass::Util.file_uri(File.absolute_path(response.url, File.dirname(file)))

            if canonicalizations.key? url
              canonicalizations[url].id = response.id
            else
              resolved = nil
              options[:importer].each do |importer|
                begin
                  resolved = importer.call response.url, file
                rescue StandardError => e
                  resolved = e
                end
                break if resolved
              end
              if resolved.nil?
                canonicalizations[url] = Sass::EmbeddedProtocol::InboundMessage::CanonicalizeResponse.new(
                  id: response.id,
                  url: url
                )
              elsif resolved.is_a? StandardError
                canonicalizations[url] = Sass::EmbeddedProtocol::InboundMessage::CanonicalizeResponse.new(
                  id: response.id,
                  error: resolved.message
                )
              elsif resolved.key? :contents
                canonicalizations[url] = Sass::EmbeddedProtocol::InboundMessage::CanonicalizeResponse.new(
                  id: response.id,
                  url: url
                )
                imports[url] = Sass::EmbeddedProtocol::InboundMessage::ImportResponse.new(
                  id: response.id,
                  success: Sass::EmbeddedProtocol::InboundMessage::ImportResponse::ImportSuccess.new(
                    contents: resolved[:contents],
                    syntax: Sass::EmbeddedProtocol::Syntax::SCSS,
                    source_map_url: nil
                  )
                )
              elsif resolved.key? :file
                canonicalized_url = Sass::Util.file_uri(resolved[:file])
                canonicalizations[url] = Sass::EmbeddedProtocol::InboundMessage::CanonicalizeResponse.new(
                  id: response.id,
                  url: canonicalized_url
                )
                imports[canonicalized_url] = Sass::EmbeddedProtocol::InboundMessage::ImportResponse.new(
                  id: response.id,
                  success: Sass::EmbeddedProtocol::InboundMessage::ImportResponse::ImportSuccess.new(
                    contents: File.read(resolved[:file]),
                    syntax: Sass::EmbeddedProtocol::Syntax::SCSS,
                    source_map_url: nil
                  )
                )
              else
                canonicalizations[url] = Sass::EmbeddedProtocol::InboundMessage::CanonicalizeResponse.new(
                  id: response.id,
                  error: "Unexpected value returned from importer: #{resolved}"
                )
              end
            end

            response = @transport.send canonicalizations[url], compilation_id
          when Sass::EmbeddedProtocol::OutboundMessage::ImportRequest
            url = response.url

            if imports.key? url
              imports[url].id = response.id
            else
              imports[url] = Sass::EmbeddedProtocol::InboundMessage::ImportResponse.new(
                id: response.id,
                error: "Failed to import: #{url}"
              )
            end

            response = @transport.send imports[url], compilation_id
          when Sass::EmbeddedProtocol::OutboundMessage::FunctionCallRequest
            begin
              message = Sass::EmbeddedProtocol::InboundMessage::FunctionCallResponse.new(
                id: response.id,
                success: functions[response.name].call(*response.arguments)
              )
            rescue StandardError => e
              message = Sass::EmbeddedProtocol::InboundMessage::FunctionCallResponse.new(
                id: response.id,
                error: e.message
              )
            end

            response = @transport.send message, compilation_id
          when Sass::EmbeddedProtocol::ProtocolError
            raise Sass::ProtocolError, response.message
          else
            raise Sass::ProtocolError, "Unexpected packet received: #{response}"
          end
        end

        if response.failure
          raise Sass::CompilationError.new(
            response.failure.message,
            response.failure.formatted,
            response.failure.span ? response.failure.span.url : nil,
            response.failure.span ? response.failure.span.start.line + 1 : nil,
            response.failure.span ? response.failure.span.start.column + 1 : nil,
            1
          )
        end

        finish = Sass::Util.now

        {
          css: response.success.css,
          map: response.success.source_map,
          stats: {
            entry: options[:file] || 'data',
            start: start,
            end: finish,
            duration: finish - start
          }
        }
      end

      def close
        @transport.close
      end

      private

      def info
        version_response = @transport.send Sass::EmbeddedProtocol::InboundMessage::VersionRequest.new(
          id: next_id
        )
        {
          compiler_version: version_response.compiler_version,
          protocol_version: version_response.protocol_version,
          implementation_name: version_response.implementation_name,
          implementation_version: version_response.implementation_version
        }
      end

      def next_id
        @id_semaphore.synchronize do
          @id += 1
          @id = 0 if @id == Transport::PROTOCOL_ERROR_ID
          @id
        end
      end
    end
  end
end
