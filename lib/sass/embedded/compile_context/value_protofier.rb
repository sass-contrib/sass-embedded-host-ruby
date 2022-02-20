# frozen_string_literal: true

module Sass
  class Embedded
    class CompileContext
      # The {ValueProtofier} between Pure Ruby types and Protobuf Ruby types.
      class ValueProtofier
        def initialize(function_registry)
          @function_registry = function_registry
        end

        def to_proto(obj)
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
                contents: obj.contents.map { |element| to_proto(element) },
                keywords: obj.keywords.transform_values { |value| to_proto(value) },
                separator: to_proto_separator(obj.separator)
              )
            )
          when Sass::Value::List
            Sass::EmbeddedProtocol::Value.new(
              list: Sass::EmbeddedProtocol::Value::List.new(
                contents: obj.contents.map { |element| to_proto(element) },
                separator: to_proto_separator(obj.separator),
                has_brackets: obj.bracketed?
              )
            )
          when Sass::Value::Map
            Sass::EmbeddedProtocol::Value.new(
              map: Sass::EmbeddedProtocol::Value::Map.new(
                entries: obj.contents.map do |key, value|
                  Sass::EmbeddedProtocol::Value::Map::Entry.new(
                    key: to_proto(key),
                    value: to_proto(value)
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

        def from_proto(proto)
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
                from_proto(i)
              end,
              value.keywords.entries.to_h do |entry|
                [entry.first, from_proto(entry.last)]
              end,
              from_proto_separator(value.separator)
            ).instance_eval do
              @id = value.id
              self
            end
          when :list
            Sass::Value::List.new(
              value.contents.map do |element|
                from_proto(element)
              end,
              separator: from_proto_separator(value.separator),
              bracketed: value.has_brackets
            )
          when :map
            Sass::Value::Map.new(
              value.entries.to_h do |entry|
                [from_proto(entry.key), from_proto(entry.value)]
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
      end

      private_constant :ValueProtofier
    end
  end
end
