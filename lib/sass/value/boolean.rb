# frozen_string_literal: true

module Sass
  module Value
    # Sass's boolean type.
    class Boolean
      include Value

      def initialize(value)
        @value = value
      end

      attr_reader :value

      alias to_bool value

      def assert_boolean(_name = nil)
        self
      end

      def ==(other)
        other.is_a?(Sass::Value::Boolean) && other.value == value
      end

      def hash
        @hash ||= value.hash
      end

      def !
        value ? Boolean::FALSE : Boolean::TRUE
      end

      # Sass's true value.
      TRUE = Boolean.new(true)

      # Sass's false value.
      FALSE = Boolean.new(false)

      def self.new(value)
        value ? Boolean::TRUE : Boolean::FALSE
      end
    end
  end
end
