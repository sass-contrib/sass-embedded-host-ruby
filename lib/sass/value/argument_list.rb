# frozen_string_literal: true

module Sass
  class Value
    # Sass's argument list type.
    #
    # An argument list comes from a rest argument. It's distinct from a normal {List} in that it may contain a keyword
    # map as well as the positional arguments.
    class ArgumentList < Sass::Value::List
      def initialize(contents = [], keywords = {}, separator = ',')
        super(contents, separator: separator)

        @id = 0
        @keywords_accessed = false
        @keywords = keywords.transform_keys(&:to_s).freeze
      end

      def keywords
        @keywords_accessed = true
        @keywords
      end
    end
  end
end
