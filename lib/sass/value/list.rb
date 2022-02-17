# frozen_string_literal: true

module Sass
  class Value
    # Sass's list type.
    class List < Sass::Value
      def initialize(contents = [], separator: ',', bracketed: false) # rubocop:disable Lint/MissingSuper
        if separator.nil? && contents.length > 1
          raise error 'A list with more than one element must have an explicit separator'
        end

        @contents = contents.freeze
        @separator = separator.freeze
        @bracketed = bracketed.freeze
      end

      attr_reader :contents, :separator

      alias to_a contents

      def bracketed?
        @bracketed
      end

      def assert_map(name = nil)
        to_a.empty? ? Sass::Value::Map.new({}) : super.assert_map(name)
      end

      def to_map
        to_a.empty? ? Sass::Value::Map.new({}) : nil
      end

      def at(index)
        index = index.floor
        index = to_a.length + index if index.negative?
        return nil if index.negative? || index >= to_a.length

        to_a[index]
      end

      def ==(other)
        (other.is_a?(Sass::Value::List) &&
         other.contents == contents &&
         other.separator == separator &&
         other.bracketed? == bracketed?) ||
          (to_a.empty? && other.is_a?(Sass::Value::Map) && other.to_a.empty?)
      end

      def hash
        @hash ||= contents.hash
      end

      private

      def to_a_length
        to_a.length
      end
    end
  end
end
