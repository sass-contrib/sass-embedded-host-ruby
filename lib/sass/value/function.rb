# frozen_string_literal: true

module Sass
  module Value
    # Sass's function type.
    #
    # @see https://sass-lang.com/documentation/js-api/classes/sassfunction/
    class Function
      include Value

      # @param signature [::String]
      # @param callback [Proc]
      def initialize(signature, &callback)
        @signature = signature.freeze
        @callback = callback.freeze
      end

      # @return [Object, nil]
      protected attr_reader :environment

      # @return [Integer, nil]
      protected attr_reader :id

      # @return [::String, nil]
      attr_reader :signature

      # @return [Proc, nil]
      attr_reader :callback

      # @return [::Boolean]
      def ==(other)
        if defined?(@id)
          other.is_a?(Sass::Value::Function) && other.environment == environment && other.id == id
        else
          other.equal?(self)
        end
      end

      # @return [Integer]
      def hash
        @hash ||= id.nil? ? signature.hash : id.hash
      end

      # @return [Function]
      def assert_function(_name = nil)
        self
      end
    end
  end
end
