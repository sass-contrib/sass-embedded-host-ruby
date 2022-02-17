# frozen_string_literal: true

module Sass
  # The {Value} abstract class.
  class Value
    def to_a
      [self]
    end

    def to_bool
      true
    end

    def to_map
      nil
    end

    def to_nil
      self
    end

    def separator
      nil
    end

    def bracketed?
      false
    end

    def sass_index_to_list_index(sass_index, name = nil)
      index = sass_index.assert_number(name).assert_integer(name)
      raise error('List index may not be 0', name) if index.zero?

      if index.abs > to_a_length
        raise error("Invalid index #{sass_index} for a list with #{to_a_length} elements",
                    name)
      end

      index.negative? ? to_a_length + index : index - 1
    end

    def at(index)
      index < 1 && index >= -1 ? self : nil
    end

    def [](index)
      at(index)
    end

    def assert_boolean(name = nil)
      raise error("#{self} is not a boolean", name)
    end

    def assert_calculation(name = nil)
      raise error("#{self} is not a calculation", name)
    end

    def assert_color(name = nil)
      raise error("#{self} is not a color", name)
    end

    def assert_function(name = nil)
      raise error("#{self} is not a function", name)
    end

    def assert_map(name = nil)
      raise error("#{self} is not a map", name)
    end

    def assert_number(name = nil)
      raise error("#{self} is not a number", name)
    end

    def assert_string(name = nil)
      raise error("#{self} is not a string", name)
    end

    def eql?(other)
      self == other
    end

    private

    def to_a_length
      1
    end

    def error(message, name = nil)
      Sass::ScriptError.new name.nil? ? message : "$#{name}: #{message}"
    end
  end
end
