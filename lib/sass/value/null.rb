# frozen_string_literal: true

module Sass
  module Value
    # Sass's null type.
    class Null
      include Value

      def initialize
        @value = nil
      end

      attr_reader :value

      alias to_nil value

      def to_bool
        false
      end

      def ==(other)
        other.is_a?(Sass::Value::Null)
      end

      def hash
        @hash ||= value.hash
      end

      def !
        Boolean::TRUE
      end

      # Sass's null value.
      NULL = Null.new

      def self.new
        NULL
      end
    end
  end
end
