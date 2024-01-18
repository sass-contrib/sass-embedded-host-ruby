# frozen_string_literal: true

module Sass
  class Compiler
    class Host
      # The {Protofier} module.
      #
      # It converts Pure Ruby types and Protobuf Ruby types.
      module Protofier
        module_function

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
      end

      private_constant :Protofier
    end
  end
end
