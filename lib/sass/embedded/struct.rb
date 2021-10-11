# frozen_string_literal: true

module Sass
  class Embedded
    # The {Struct} module.
    module Struct
      def [](key)
        instance_variable_get("@#{key}".to_sym)
      end

      def to_h
        instance_variables.map do |variable|
          [variable[1..].to_sym, instance_variable_get(variable)]
        end.to_h
      end

      def to_s
        to_h.to_s
      end
    end

    private_constant :Struct
  end
end
