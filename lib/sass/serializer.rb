# frozen_string_literal: true

module Sass
  # The {Serializer} module.
  module Serializer
    module_function

    def serialize_quoted_string(string, ascii_only: false)
      buffer = [0x22]
      string.each_codepoint do |codepoint|
        if codepoint.zero?
          # If the character is NULL (U+0000), then the REPLACEMENT CHARACTER (U+FFFD).
          buffer << 0xFFFD
        elsif codepoint == 0x22
          # If the character is '"' (U+0022) or "\" (U+005C), then the escaped character.
          buffer << 0x5C << 0x22
        elsif codepoint == 0x5C
          # If the character is '"' (U+0022) or "\" (U+005C), then the escaped character.
          buffer << 0x5C << 0x5C
        elsif codepoint < 0x20 || (ascii_only ? codepoint >= 0x7F : codepoint == 0x7F)
          # If the character is in the range [\1-\1f] (U+0001 to U+001F) or is U+007F,
          # then the character escaped as code point.
          buffer << 0x5C
          buffer.concat(codepoint.to_s(16).codepoints)
          buffer << 0x20
        else
          # Otherwise, the character itself.
          buffer << codepoint
        end
      end
      buffer << 0x22
      buffer.pack('U*')
    end

    def serialize_unquoted_string(string)
      string.tr("\0", "\uFFFD").gsub(/\n */, ' ')
    end
  end

  private_constant :Serializer
end
