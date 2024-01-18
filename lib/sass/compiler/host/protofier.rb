# frozen_string_literal: true

module Sass
  class Compiler
    class Host
      # The {Protofier} module.
      #
      # It converts Pure Ruby types and Protobuf Ruby types.
      module Protofier
        module_function

        def from_proto_compile_response(compile_response)
          oneof = compile_response.result
          result = compile_response.public_send(oneof)
          case oneof
          when :failure
            raise CompileError.new(
              result.message,
              result.formatted == '' ? nil : result.formatted,
              result.stack_trace == '' ? nil : result.stack_trace,
              result.span.nil? ? nil : Logger::SourceSpan.new(result.span),
              compile_response.loaded_urls
            )
          when :success
            CompileResult.new(
              result.css,
              result.source_map == '' ? nil : result.source_map,
              compile_response.loaded_urls
            )
          else
            raise ArgumentError, "Unknown CompileResponse.result #{result}"
          end
        end

        def to_proto_syntax(syntax)
          case syntax&.to_sym
          when :scss
            EmbeddedProtocol::Syntax::SCSS
          when :indented
            EmbeddedProtocol::Syntax::INDENTED
          when :css
            EmbeddedProtocol::Syntax::CSS
          else
            raise ArgumentError, 'syntax must be one of :scss, :indented, :css'
          end
        end

        def to_proto_output_style(style)
          case style&.to_sym
          when :expanded
            EmbeddedProtocol::OutputStyle::EXPANDED
          when :compressed
            EmbeddedProtocol::OutputStyle::COMPRESSED
          else
            raise ArgumentError, 'style must be one of :expanded, :compressed'
          end
        end
      end

      private_constant :Protofier
    end
  end
end
