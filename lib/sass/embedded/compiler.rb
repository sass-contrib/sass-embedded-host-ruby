# frozen_string_literal: true

module Sass
  module Embedded
    class Compiler

      def initialize
        if defined? @@pwd
          if @@pwd == Dir.pwd
            return
          else
            @@transport.close
          end
        end

        @@transport = Transport.new
        @@pwd = Dir.pwd

        @@id_semaphore = Mutex.new
        @@id = 0
      end

      def render options
        start = Sass::Util.now

        if options[:file].nil? && options[:data].nil?
          raise Sass::NotRenderedError.new 'Either :data or :file must be set.'
        end

        if options[:file].nil? && Dir.pwd != @@pwd
          raise Sass::NotRenderedError.new 'Working directory changed after launching `dart-sass-embedded`.'
        end

        string = options[:data] ? Sass::EmbeddedProtocol::InboundMessage::CompileRequest::StringInput.new(
          :source => options[:data],
          :url => options[:file] ? Sass::Util.file_uri(options[:file]) : 'stdin',
          :syntax => options[:indented_syntax] == true ? Sass::EmbeddedProtocol::Syntax::INDENTED : Sass::EmbeddedProtocol::Syntax::SCSS
        ) : nil

        path = options[:data] ? nil : options[:file]

        style = case options[:output_style]&.to_sym
                when :expanded, nil
                  Sass::EmbeddedProtocol::OutputStyle::EXPANDED
                when :compressed
                  Sass::EmbeddedProtocol::OutputStyle::COMPRESSED
                when :nested, :compact
                  raise Sass::UnsupportedValue.new "#{options[:output_style]} is not a supported :output_style"
                else
                  raise Sass::InvalidStyleError.new "#{options[:output_style]} is not a valid :output_style"
                end

        source_map = options[:source_map].is_a? String || (options[:source_map] == true && !!options[:out_file])

        # 1. Loading a file relative to the file in which the @use or @import appeared.
        # 2. Each custom importer.
        # 3. Loading a file relative to the current working directory.
        # 4. Each load path in includePaths
        # 5. Each load path specified in the SASS_PATH environment variable, which should be semicolon-separated on Windows and colon-separated elsewhere.
        importers = (options[:importer] ? [
          Sass::EmbeddedProtocol::InboundMessage::CompileRequest::Importer.new( :importer_id => 0 )
        ] : []).concat(
          (options[:include_paths] || []).concat(Sass.include_paths)
          .map { |path| Sass::EmbeddedProtocol::InboundMessage::CompileRequest::Importer.new(
            :path => File.absolute_path(path)
          )}
        )

        signatures = []
        functions = {}
        options[:functions]&.each { |signature, function|
          signatures.push signature
          functions[signature.to_s.split('(')[0].chomp] = function
        }

        compilation_id = next_id

        compile_request = Sass::EmbeddedProtocol::InboundMessage::CompileRequest.new(
          :id               => compilation_id,
          :string           => string,
          :path             => path,
          :style            => style,
          :source_map       => source_map,
          :importers        => importers,
          :global_functions => options[:functions] ? signatures : [],
          :alert_color      => true,
          :alert_ascii      => true
        )

        response = @@transport.send compile_request, compilation_id

        file = options[:file] || 'stdin'
        canonicalizations = {}
        imports = {}

        loop do
          case response
          when Sass::EmbeddedProtocol::OutboundMessage::CompileResponse
            break
          when Sass::EmbeddedProtocol::OutboundMessage::CanonicalizeRequest
            url = Sass::Util.file_uri(File.absolute_path(response.url, File.dirname(file)))

            if canonicalizations.has_key? url
              canonicalizations[url].id = response.id
            else
              resolved = nil
              options[:importer].each { |importer|
                begin
                  resolved = importer.call response.url, file
                rescue Exception => error
                  resolved = error
                end
                break if resolved
              }
              if resolved.nil?
                canonicalizations[url] = Sass::EmbeddedProtocol::InboundMessage::CanonicalizeResponse.new(
                  :id  => response.id,
                  :url => url
                )
              elsif resolved.is_a? Exception
                canonicalizations[url] = Sass::EmbeddedProtocol::InboundMessage::CanonicalizeResponse.new(
                  :id    => response.id,
                  :error => resolved.message
                )
              elsif resolved.has_key? :contents
                canonicalizations[url] = Sass::EmbeddedProtocol::InboundMessage::CanonicalizeResponse.new(
                  :id  => response.id,
                  :url => url
                )
                imports[url] = Sass::EmbeddedProtocol::InboundMessage::ImportResponse.new(
                  :id      => response.id,
                  :success => Sass::EmbeddedProtocol::InboundMessage::ImportResponse::ImportSuccess.new(
                    :contents       => resolved[:contents],
                    :syntax         => Sass::EmbeddedProtocol::Syntax::SCSS,
                    :source_map_url => nil
                  )
                )
              elsif resolved.has_key? :file
                canonicalized_url = Sass::Util.file_uri(resolved[:file])
                canonicalizations[url] = Sass::EmbeddedProtocol::InboundMessage::CanonicalizeResponse.new(
                  :id  => response.id,
                  :url => canonicalized_url
                )
                imports[canonicalized_url] = Sass::EmbeddedProtocol::InboundMessage::ImportResponse.new(
                  :id      => response.id,
                  :success => Sass::EmbeddedProtocol::InboundMessage::ImportResponse::ImportSuccess.new(
                    :contents       => File.read(resolved[:file]),
                    :syntax         => Sass::EmbeddedProtocol::Syntax::SCSS,
                    :source_map_url => nil
                  )
                )
              else
                canonicalizations[url] = Sass::EmbeddedProtocol::InboundMessage::CanonicalizeResponse.new(
                  :id    => response.id,
                  :error => "Unexpected value returned from importer: #{resolved}"
                )
              end
            end

            response = @@transport.send canonicalizations[url], compilation_id
          when Sass::EmbeddedProtocol::OutboundMessage::ImportRequest
            url = response.url

            if imports.has_key? url
              imports[url].id = response.id
            else
              imports[url] = Sass::EmbeddedProtocol::InboundMessage::ImportResponse.new(
                :id    => response.id,
                :error => "Failed to import: #{url}"
              )
            end

            response = @@transport.send imports[url], compilation_id
          when Sass::EmbeddedProtocol::OutboundMessage::FunctionCallRequest
            begin
              message = Sass::EmbeddedProtocol::InboundMessage::FunctionCallResponse.new(
                :id      => response.id,
                :success => functions[response.name].call(*response.arguments)
              )
            rescue Exception => error
              message = Sass::EmbeddedProtocol::InboundMessage::FunctionCallResponse.new(
                :id    => response.id,
                :error => error.message
              )
            end

            response = @@transport.send message, compilation_id
          when Sass::EmbeddedProtocol::ProtocolError
            raise Sass::ProtocolError.new response.message
          else
            raise Sass::ProtocolError.new "Unexpected packet received: #{response}"
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

        return {
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

      private

      def info
        version_response = @@transport.send Sass::EmbeddedProtocol::InboundMessage::VersionRequest.new(
          :id => next_id
        )
        return {
          compiler_version: version_response.compiler_version,
          protocol_version: version_response.protocol_version,
          implementation_name: version_response.implementation_name,
          implementation_version: version_response.implementation_version
        }
      end

      def next_id
        @@id_semaphore.synchronize {
          @@id += 1
          if @@id == Transport::PROTOCOL_ERROR_ID
            @@id = 0
          end
          @@id
        }
      end

      def restart
        @@transport.close
        @@transport = Transport.new
      end
    end
  end
end
