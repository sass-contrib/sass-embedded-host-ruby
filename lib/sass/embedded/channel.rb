# frozen_string_literal: true

module Sass
  class Embedded
    # The {Channel} class.
    #
    # It establishes connection between {Host} and {Dispatcher}.
    class Channel
      def initialize
        @dispatcher = Dispatcher.new
        @mutex = Mutex.new
      end

      def close
        @mutex.synchronize do
          @dispatcher.close
        end
      end

      def closed?
        @mutex.synchronize do
          @dispatcher.closed?
        end
      end

      def connect(observer)
        @mutex.synchronize do
          @dispatcher.connect(observer)
        rescue Errno::EBUSY
          @dispatcher = Dispatcher.new
          @dispatcher.connect(observer)
        end
      end
    end

    private_constant :Channel
  end
end
