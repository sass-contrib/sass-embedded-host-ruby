# frozen_string_literal: true

module Sass
  class Compiler
    class Session
      # @see https://pub.dev/documentation/stack_trace/latest/stack_trace/
      module StackTrace
        module_function

        # @see https://pub.dev/documentation/stack_trace/latest/stack_trace/Trace/toString.html
        def pretty_formatted!(formatted, stack_trace)
          longest = 0

          frames = stack_trace.lines("\n", chomp: true).map do |frame|
            location, member = frame.split(/  +/, 2)
            uri, line_column = location.split(' ', 2)

            uri = Path.pretty_uri(uri)
            location = line_column.nil? ? uri : "#{uri} #{line_column}"

            longest = location.length if location.length > longest
            [frame, location, member]
          end

          offset = formatted.length

          frames.reverse_each do |frame, location, member|
            index = formatted.rindex(frame, offset)
            next unless index

            offset = index

            replacement = "#{location.ljust(longest)}  #{member}"
            next if frame == replacement

            formatted[index, frame.length] = replacement
          end

          formatted
        end
      end

      private_constant :StackTrace
    end
  end
end
