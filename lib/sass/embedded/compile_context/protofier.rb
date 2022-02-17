# frozen_string_literal: true

module Sass
  class Embedded
    class CompileContext
      # The {Protofier} between Pure Ruby types and Protobuf Ruby types.
      class Protofier
        ONEOF_VALUE = EmbeddedProtocol::Value
                      .descriptor
                      .lookup_oneof('value')
                      .to_h do |field_descriptor|
          [field_descriptor.subtype, field_descriptor.name]
        end

        private_constant :ONEOF_VALUE

        def initialize(function_registry)
          @function_registry = function_registry
        end

        def to_proto(obj)
          value = case obj
                  when Sass::Value::String
                    Sass::EmbeddedProtocol::Value::String.new(
                      text: obj.text,
                      quoted: obj.quoted?
                    )
                  when Sass::Value::Number
                    Sass::EmbeddedProtocol::Value::Number.new(
                      value: obj.value,
                      numerators: obj.numerator_units,
                      denominators: obj.denominator_units
                    )
                  when Sass::Value::Color
                    if value.instance_eval { @hue.nil? }
                      Sass::EmbeddedProtocol::Value::RgbColor.new(
                        hue: obj.hue,
                        saturation: obj.saturation,
                        lightness: obj.lightness,
                        alpha: obj.alpha
                      )
                    else
                      Sass::EmbeddedProtocol::Value::HslColor.new(
                        red: obj.red,
                        green: obj.green,
                        blue: obj.blue,
                        alpha: obj.alpha
                      )
                    end
                  when Sass::Value::List
                    Sass::EmbeddedProtocol::Value::List.new(
                      separator: to_proto_separator(obj.separator),
                      has_brackets: obj.bracketed?,
                      contents: obj.contents.map(method(:to_proto))
                    )
                  when Sass::Value::ArgumentList
                    Sass::EmbeddedProtocol::Value::ArgumentList.new(
                      id: obj.instance_eval { @id },
                      separator: to_proto_separator(obj.separator),
                      contents: obj.contents.map(method(:to_proto)),
                      keywords: obj.keywords.transform_values(method(:to_proto))
                    )
                  when Sass::Value::Map
                    Sass::EmbeddedProtocol::Value::Map.new(
                      entries: obj.to_a.map do |entry|
                        Sass::EmbeddedProtocol::Value::Map::Entry.new(
                          key: to_proto(entry.first),
                          value: to_proto(entry.last)
                        )
                      end
                    )
                  when Sass::Value::Function
                    if obj.id
                      Sass::EmbeddedProtocol::Value::CompilerFunction.new(
                        id: obj.id
                      )
                    else
                      Sass::EmbeddedProtocol::Value::HostFunction.new(
                        id: @function_registry.register(obj.callback),
                        signature: obj.signature
                      )
                    end
                  when Sass::Value::Boolean
                    return Sass::EmbeddedProtocol::Value.new(
                      singleton: obj.value ? :TRUE : :FALSE
                    )
                  when Sass::Value::Null
                    return Sass::EmbeddedProtocol::Value.new(
                      singleton: :NULL
                    )
                  else
                    raise ArgumentError
                  end

          Sass::EmbeddedProtocol::Value.new(
            ONEOF_VALUE[value.class.descriptor] => value
          )
        end

        def from_proto(proto)
          value = proto.method(proto.value).call
          case value
          when Sass::EmbeddedProtocol::Value::String
            Sass::Value::String.new(value.text, quoted: value.quoted)
          when Sass::EmbeddedProtocol::Value::Number
            Sass::Value::Number.new(value.value, value.numerators, value.denominators)
          when Sass::EmbeddedProtocol::Value::RgbColor
            Sass::Value::Color.new(red: value.red, green: value.green, blue: value.blue, alpha: value.alpha)
          when Sass::EmbeddedProtocol::Value::HslColor
            Sass::Value::Color.new(hue: value.hue, saturation: value.saturation, lightness: value.lightness,
                                   alpha: value.alpha)
          when Sass::EmbeddedProtocol::Value::List
            Sass::Value::List.new(value.contents.map do |i|
              from_proto(i)
            end,
                                  separator: from_proto_separator(value.separator), bracketed: value.has_brackets)
          when Sass::EmbeddedProtocol::Value::ArgumentList
            Sass::Value::ArgumentList.new(
              value.contents.map do |i|
                from_proto(i)
              end,
              value.keywords.entries.to_h do |entry|
                [entry.first, from_proto(entry.last)]
              end
            ).instance_eval do
              @id = value.id
              self
            end
          when Sass::EmbeddedProtocol::Value::Map
            Sass::Value::Map.new(value.entries.to_h { |entry| [from_proto(entry.key), from_proto(entry.value)] })
          when Sass::EmbeddedProtocol::Value::CompilerFunction
            Sass::Value::Function.new(value.id)
          when Sass::EmbeddedProtocol::Value::HostFunction
            raise ProtocolError, 'The compiler may not send Value.host_function'
          when :TRUE
            Sass::Value::TRUE
          when :FALSE
            Sass::Value::FALSE
          when :NULL
            Sass::Value::NULL
          else
            raise "The compiler must send Value.value #{value}"
          end
        end

        class << self
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

          def to_struct(obj)
            return obj unless obj.is_a? Hash

            struct = Object.new
            obj.each do |key, value|
              if value.respond_to? :call
                struct.define_singleton_method key.to_sym do |*args, **kwargs|
                  value.call(*args, **kwargs)
                end
              else
                struct.define_singleton_method key.to_sym do
                  value
                end
              end
            end
            struct
          end
        end
      end

      private_constant :Protofier
    end
  end
end
