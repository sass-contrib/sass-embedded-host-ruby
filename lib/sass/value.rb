# frozen_string_literal: true

module Sass
  # The abstract base class of Sass's value types.
  #
  # @see https://sass-lang.com/documentation/js-api/classes/value/
  module Value
    # @return [::String, nil]
    def separator
      nil
    end

    # @return [::Boolean]
    def bracketed?
      false
    end

    # @return [::Boolean]
    def eql?(other)
      self == other
    end

    # @param index [Numeric]
    # @return [Value]
    def [](index)
      at(index)
    end

    # @param index [Numeric]
    # @return [Value]
    def at(index)
      index < 1 && index >= -1 ? self : nil
    end

    # @return [Array<Value>]
    def to_a
      [self]
    end

    # @return [Hash<Value, Value>]
    # @raise [ScriptError, ArgumentError, TypeError]
    def to_h(...)
      to_a.to_h(...)
    end

    # @return [::String]
    # @raise [ScriptError]
    def to_s
      s = nil
      Sass.compile_string('$_:o(#{i()});', functions: { # rubocop:disable Lint/InterpolationCheck
                            'i()' => ->(_) { self },
                            'o($s)' => ->(args) { s = args[0].assert_string }
                          })
      s.text
    rescue Sass::CompileError => e
      raise Sass::ScriptError.new(e.message), cause: nil
    end

    # @return [::String]
    def inspect
      s = nil
      Sass.compile_string('@use "sass:meta";$_:o(meta.inspect(i()));', functions: {
                            'i()' => ->(_) { self },
                            'o($s)' => ->(args) { s = args[0].assert_string }
                          })
      s.text
    rescue StandardError
      super
    end

    # @return [::Boolean]
    def to_bool # rubocop:disable Naming/PredicateMethod
      true
    end

    # @return [Map, nil]
    def to_map
      nil
    end

    # @return [Value, nil]
    def to_nil
      self
    end

    # @return [Boolean]
    # @raise [ScriptError]
    def assert_boolean(name = nil)
      raise Sass::ScriptError.new("#{inspect} is not a boolean", name)
    end

    # @return [Calculation]
    # @raise [ScriptError]
    def assert_calculation(name = nil)
      raise Sass::ScriptError.new("#{inspect} is not a calculation", name)
    end

    # @return [Color]
    # @raise [ScriptError]
    def assert_color(name = nil)
      raise Sass::ScriptError.new("#{inspect} is not a color", name)
    end

    # @return [Function]
    # @raise [ScriptError]
    def assert_function(name = nil)
      raise Sass::ScriptError.new("#{inspect} is not a function", name)
    end

    # @return [Map]
    # @raise [ScriptError]
    def assert_map(name = nil)
      raise Sass::ScriptError.new("#{inspect} is not a map", name)
    end

    # @return [Mixin]
    # @raise [ScriptError]
    def assert_mixin(name = nil)
      raise Sass::ScriptError.new("#{inspect} is not a mixin", name)
    end

    # @return [Module]
    # @raise [ScriptError]
    def assert_module(name = nil)
      raise Sass::ScriptError.new("#{inspect} is not a module", name)
    end

    # @return [Number]
    # @raise [ScriptError]
    def assert_number(name = nil)
      raise Sass::ScriptError.new("#{inspect} is not a number", name)
    end

    # @return [String]
    # @raise [ScriptError]
    def assert_string(name = nil)
      raise Sass::ScriptError.new("#{inspect} is not a string", name)
    end

    # @param sass_index [Number]
    # @return [Integer]
    def sass_index_to_array_index(sass_index, name = nil)
      index = sass_index.assert_number(name).assert_integer(name)
      raise Sass::ScriptError.new('List index may not be 0', name) if index.zero?

      if index.abs > to_a_length
        raise Sass::ScriptError.new("Invalid index #{sass_index} for a list with #{to_a_length} elements", name)
      end

      index.negative? ? to_a_length + index : index - 1
    end

    private

    def to_a_length
      1
    end
  end
end

require_relative 'calculation_value'
require_relative 'value/list'
require_relative 'value/argument_list'
require_relative 'value/boolean'
require_relative 'value/calculation'
require_relative 'value/color'
require_relative 'value/function'
require_relative 'value/fuzzy_math'
require_relative 'value/map'
require_relative 'value/mixin'
require_relative 'value/module'
require_relative 'value/null'
require_relative 'value/number'
require_relative 'value/string'
