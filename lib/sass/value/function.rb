# frozen_string_literal: true

module Sass
  class Value
    # Sass's function type.
    class Function < Sass::Value
      def initialize(id_or_signature, callback = nil) # rubocop:disable Lint/MissingSuper
        if id_or_signature.is_a? Numeric
          @id = id_or_signature
        else
          @signature = id_or_signature
          @callback = callback
        end
      end

      attr_reader :id, :signature, :callback

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
