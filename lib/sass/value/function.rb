# frozen_string_literal: true

module Sass
  module Value
    # Sass's function type.
    class Function
      include Value

      def initialize(id_or_signature, callback = nil)
        if id_or_signature.is_a? Numeric
          @id = id_or_signature
        else
          @signature = id_or_signature
          @callback = callback
        end
      end

      attr_reader :id, :signature, :callback

      def assert_function(_name = nil)
        self
      end

      def ==(other)
        if id.nil?
          other.equal? self
        else
          other.is_a?(Sass::Value::Function) && other.id == id
        end
      end

      def hash
        id.nil? ? signature.hash : id.hash
      end
    end
  end
end
