# frozen_string_literal: true

module Sass
  class Embedded
    # The {Protofier} between Pure Ruby types and Protobuf Ruby types.
    class Protofier
      ONEOF_MESSAGE = EmbeddedProtocol::InboundMessage
                      .descriptor
                      .lookup_oneof('message')
                      .to_h do |field_descriptor|
        [field_descriptor.subtype, field_descriptor.name]
      end

      private_constant :ONEOF_MESSAGE

      def initialize(function_registry)
        @function_registry = function_registry
      end

      def to_proto_value(obj)
        case obj
        when Sass::Value::String
          Sass::EmbeddedProtocol::Value.new(
            string: Sass::EmbeddedProtocol::Value::String.new(
              text: obj.text,
              quoted: obj.quoted?
            )
          )
        when Sass::Value::Number
          Sass::EmbeddedProtocol::Value.new(
            number: Sass::EmbeddedProtocol::Value::Number.new(
              value: obj.value.to_f,
              numerators: obj.numerator_units,
              denominators: obj.denominator_units
            )
          )
        when Sass::Value::Color
          if obj.instance_eval { @hue.nil? }
            Sass::EmbeddedProtocol::Value.new(
              rgb_color: Sass::EmbeddedProtocol::Value::RgbColor.new(
                red: obj.red,
                green: obj.green,
                blue: obj.blue,
                alpha: obj.alpha.to_f
              )
            )
          elsif obj.instance_eval { @saturation.nil? }
            Sass::EmbeddedProtocol::Value.new(
              hwb_color: Sass::EmbeddedProtocol::Value::HwbColor.new(
                hue: obj.hue.to_f,
                whiteness: obj.whiteness.to_f,
                blackness: obj.blackness.to_f,
                alpha: obj.alpha.to_f
              )
            )
          else
            Sass::EmbeddedProtocol::Value.new(
              hsl_color: Sass::EmbeddedProtocol::Value::HslColor.new(
                hue: obj.hue.to_f,
                saturation: obj.saturation.to_f,
                lightness: obj.lightness.to_f,
                alpha: obj.alpha.to_f
              )
            )
          end
        when Sass::Value::ArgumentList
          Sass::EmbeddedProtocol::Value.new(
            argument_list: Sass::EmbeddedProtocol::Value::ArgumentList.new(
              id: obj.instance_eval { @id },
              contents: obj.contents.map { |element| to_proto_value(element) },
              keywords: obj.keywords.transform_values { |value| to_proto_value(value) },
              separator: to_proto_separator(obj.separator)
            )
          )
        when Sass::Value::List
          Sass::EmbeddedProtocol::Value.new(
            list: Sass::EmbeddedProtocol::Value::List.new(
              contents: obj.contents.map { |element| to_proto_value(element) },
              separator: to_proto_separator(obj.separator),
              has_brackets: obj.bracketed?
            )
          )
        when Sass::Value::Map
          Sass::EmbeddedProtocol::Value.new(
            map: Sass::EmbeddedProtocol::Value::Map.new(
              entries: obj.contents.map do |key, value|
                Sass::EmbeddedProtocol::Value::Map::Entry.new(
                  key: to_proto_value(key),
                  value: to_proto_value(value)
                )
              end
            )
          )
        when Sass::Value::Function
          if obj.id
            Sass::EmbeddedProtocol::Value.new(
              compiler_function: Sass::EmbeddedProtocol::Value::CompilerFunction.new(
                id: obj.id
              )
            )
          else
            Sass::EmbeddedProtocol::Value.new(
              host_function: Sass::EmbeddedProtocol::Value::HostFunction.new(
                id: @function_registry.register(obj.callback),
                signature: obj.signature
              )
            )
          end
        when Sass::Value::Boolean
          Sass::EmbeddedProtocol::Value.new(
            singleton: obj.value ? :TRUE : :FALSE
          )
        when Sass::Value::Null
          Sass::EmbeddedProtocol::Value.new(
            singleton: :NULL
          )
        else
          raise Sass::ScriptError, "Unknown Sass::Value #{obj}"
        end
      end

      def from_proto_value(proto)
        value = proto.method(proto.value).call
        case proto.value
        when :string
          Sass::Value::String.new(
            value.text,
            quoted: value.quoted
          )
        when :number
          Sass::Value::Number.new(
            value.value,
            value.numerators,
            value.denominators
          )
        when :rgb_color
          Sass::Value::Color.new(
            red: value.red,
            green: value.green,
            blue: value.blue,
            alpha: value.alpha
          )
        when :hsl_color
          Sass::Value::Color.new(
            hue: value.hue,
            saturation: value.saturation,
            lightness: value.lightness,
            alpha: value.alpha
          )
        when :hwb_color
          Sass::Value::Color.new(
            hue: value.hue,
            whiteness: value.whiteness,
            blackness: value.blackness,
            alpha: value.alpha
          )
        when :argument_list
          Sass::Value::ArgumentList.new(
            value.contents.map do |i|
              from_proto_value(i)
            end,
            value.keywords.entries.to_h do |entry|
              [entry.first, from_proto_value(entry.last)]
            end,
            from_proto_separator(value.separator)
          ).instance_eval do
            @id = value.id
            self
          end
        when :list
          Sass::Value::List.new(
            value.contents.map do |element|
              from_proto_value(element)
            end,
            separator: from_proto_separator(value.separator),
            bracketed: value.has_brackets
          )
        when :map
          Sass::Value::Map.new(
            value.entries.to_h do |entry|
              [from_proto_value(entry.key), from_proto_value(entry.value)]
            end
          )
        when :compiler_function
          Sass::Value::Function.new(value.id)
        when :host_function
          raise ProtocolError, 'The compiler may not send Value.host_function to host'
        when :singleton
          case value
          when :TRUE
            Sass::Value::Boolean::TRUE
          when :FALSE
            Sass::Value::Boolean::FALSE
          when :NULL
            Sass::Value::Null::NULL
          else
            raise Sass::ScriptError "Unknown Value.singleton #{value}"
          end
        else
          raise Sass::ScriptError, "Unknown Value.value #{value}"
        end
      end

      private

      def to_proto_separator(separator)
        case separator
        when ','
          :COMMA
        when ' '
          :SPACE
        when '/'
          :SLASH
        when nil
          :UNDECIDED
        else
          raise Sass::ScriptError, "Unknown ListSeparator #{separator}"
        end
      end

      def from_proto_separator(separator)
        case separator
        when :COMMA
          ','
        when :SPACE
          ' '
        when :SLASH
          '/'
        when :UNDECIDED
          nil
        else
          raise Sass::ScriptError, "Unknown ListSeparator #{separator}"
        end
      end

      class << self
        def from_proto_compile_response(compile_response)
          if compile_response.result == :failure
            raise CompileError.new(
              compile_response.failure.formatted || compile_response.failure.message,
              compile_response.failure.message,
              compile_response.failure.stack_trace,
              from_proto_source_span(compile_response.failure.span)
            )
          end

          CompileResult.new(
            compile_response.success.css,
            compile_response.success.source_map,
            compile_response.success.loaded_urls
          )
        end

        def from_proto_source_span(source_span)
          return nil if source_span.nil?

          Logger::SourceSpan.new(from_proto_source_location(source_span.start),
                                 from_proto_source_location(source_span.end),
                                 source_span.text,
                                 source_span.url,
                                 source_span.context)
        end

        def from_proto_source_location(source_location)
          return nil if source_location.nil?

          Logger::SourceLocation.new(source_location.offset,
                                     source_location.line,
                                     source_location.column)
        end

        def from_proto_message(proto)
          message = EmbeddedProtocol::OutboundMessage.decode(proto)
          message.method(message.message).call
        end

        def to_proto_message(message)
          EmbeddedProtocol::InboundMessage.new(
            ONEOF_MESSAGE[message.class.descriptor] => message
          ).to_proto
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
    end

    private_constant :Protofier
  end
end
