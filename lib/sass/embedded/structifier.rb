# frozen_string_literal: true

module Sass
  class Embedded
    # The {Structifier} that convert {::Hash} to {Struct}-like object.
    module Structifier
      module_function

      def to_struct(obj)
        return obj unless obj.is_a? Hash

        struct = Object.new
        obj.each do |key, value|
          if value.respond_to? :call
            struct.define_singleton_method key.to_sym do |*args, **kwargs|
              if kwargs.empty?
                value.call(*args)
              else
                value.call(*args, **kwargs)
              end
            end
          else
            struct.define_singleton_method key.to_sym do
              value
            end
          end
        end
        struct
      end
    end

    private_constant :Structifier
  end
end
