# frozen_string_literal: true

module Sass
  class Compiler
    class Host
      # The {Struct} module.
      #
      # It creates {Struct}-like objects from {::Hash}.
      class Struct
        def initialize(hash, attrs: nil, methods: nil)
          @hash = hash
          @attrs = attrs
          @methods = methods
        end

        def method_missing(symbol, ...)
          return super unless @hash.key?(symbol)

          if @attrs&.include?(symbol)
            @hash.send(:[], symbol, ...)
          elsif @methods&.include?(symbol)
            @hash[symbol].call(...)
          else
            super
          end
        end

        def respond_to_missing?(symbol, _include_all)
          @hash.key?(symbol) && (@attrs&.include?(symbol) || @methods&.include?(symbol))
        end

        class << self
          def from_hash(object, ...)
            if object.is_a?(Hash)
              new(object, ...)
            else
              object
            end
          end
        end
      end

      private_constant :Struct
    end
  end
end
