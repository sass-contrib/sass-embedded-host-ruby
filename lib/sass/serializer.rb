# frozen_string_literal: true

module Sass
  # The {Serializer} module.
  module Serializer
    module_function

    def dump_quoted_string(string, force_double_quote: false)
      include_single_quote = false
      include_double_quote = false

      buffer = [0]
      string.each_codepoint do |codepoint|
        case codepoint
        when 34
          case
          when force_double_quote
            buffer << 92 << 34
          when include_single_quote
            return dump_quoted_string(string, force_double_quote: true)
          else
            include_double_quote = true
            buffer << 34
          end
        when 39
          case
          when force_double_quote
            buffer << 39
          when include_double_quote
            return dump_quoted_string(string, force_double_quote: true)
          else
            include_single_quote = true
            buffer << 39
          end
        when 92
          buffer << 92 << 92
        when 9
          buffer << 9
        else
          if codepoint < 32 || codepoint > 126
            buffer << 92
            buffer.concat(codepoint.to_s(16).codepoints)
            buffer << 32
          else
            buffer << codepoint
          end
        end
      end
      buffer[0] = force_double_quote || !include_double_quote ? 34 : 39
      buffer << buffer[0]
      buffer.pack('U*')
    end
  end

  private_constant :Serializer
end
