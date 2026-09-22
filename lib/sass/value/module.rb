# frozen_string_literal: true

module Sass
  module Value
    # Sass's module type.
    #
    # @see https://sass-lang.com/documentation/js-api/classes/sassmodule/
    class Module
      include Value

      class << self
        private :new
      end

      # @return [Object]
      protected attr_reader :compile_context

      # @return [Integer]
      protected attr_reader :id

      # @return [::Boolean]
      def ==(other)
        other.is_a?(Sass::Value::Module) && other.compile_context == compile_context && other.id == id
      end

      # @return [Integer]
      def hash
        @hash ||= [compile_context, id].hash
      end

      # @return [Module]
      def assert_module(_name = nil)
        self
      end
    end
  end
end
