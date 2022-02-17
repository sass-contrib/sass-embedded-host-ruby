# frozen_string_literal: true

module Sass
  class Value
    # Sass's boolean type.
    class Boolean < Sass::Value
      def initialize(value) # rubocop:disable Lint/MissingSuper
        @value = value
      end

      attr_reader :value

      alias to_bool value

      def assert_boolean
        self
      end

      def ==(other)
        other.is_a?(Sass::Value::Boolean) && other.value == value
      end

      def hash
        @hash ||= value.hash
      end

      def !
        value ? Value::FALSE : Value::TRUE
      end
    end

    # Sass's true value.
    TRUE = Boolean.new(true)

    # Sass's false value.
    FALSE = Boolean.new(false)

    # Sass's boolean type.
    class Boolean
      def self.new(value)
        value ? Value::TRUE : Value::FALSE
      end
    end
  end
end
