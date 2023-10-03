# frozen_string_literal: true

module Sass
  module Value
    # Sass's mixin type.
    #
    # @see https://sass-lang.com/documentation/js-api/classes/sassmixin/
    class Mixin
      include Value

      # @return [Integer]
      protected attr_reader :id # rubocop:disable Style/AccessModifierDeclarations

      # @return [::Boolean]
      def ==(other)
        other.is_a?(Sass::Value::Mixin) && other.id == id
      end

      # @return [Integer]
      def hash
        @hash ||= id.hash
      end

      # @return [Mixin]
      def assert_mixin(_name = nil)
        self
      end
    end
  end
end
