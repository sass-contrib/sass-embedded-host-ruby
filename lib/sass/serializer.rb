# frozen_string_literal: true

module Sass
  # The {Serializer} module.
  module Serializer
    module_function

    def dump_quoted_string(string)
      include_double_quote = false
      include_single_quote = false
      buffer = [34]
      string.each_codepoint do |codepoint|
        case codepoint
        when 34
          return dump_double_quoted_string(string) if include_single_quote

          include_double_quote = true
          buffer << 34
        when 39
          return dump_double_quoted_string(string) if include_double_quote

          include_single_quote = true
          buffer << 39
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
      if include_double_quote
        buffer[0] = 39
        buffer << 39
      else
        buffer << 34
      end
      buffer.pack('U*')
    end

    def dump_double_quoted_string(string)
      buffer = [34]
      string.each_codepoint do |codepoint|
        case codepoint
        when 34
          buffer << 92 << 34
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
      buffer << 34
      buffer.pack('U*')
    end
  end

  private_constant :Serializer
end
