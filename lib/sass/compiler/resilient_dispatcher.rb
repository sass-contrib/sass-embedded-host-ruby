# frozen_string_literal: true

module Sass
  class Compiler
    # The {ResilientDispatcher} class.
    #
    # It recovers from failures and continues to function.
    class ResilientDispatcher
      def initialize(dispatcher_class)
        @dispatcher_class = dispatcher_class
        @dispatcher = @dispatcher_class.new
        @mutex = Mutex.new
      end

      def close(...)
        @mutex.synchronize do
          @dispatcher.close(...)
        end
      end

      def closed?(...)
        @mutex.synchronize do
          @dispatcher.closed?(...)
        end
      end

      def connect(...)
        @dispatcher.connect(...)
      rescue Errno::EBUSY
        @mutex.synchronize do
          @dispatcher.connect(...)
        rescue Errno::EBUSY
          @dispatcher = @dispatcher_class.new
          @dispatcher.connect(...)
        end
      end
    end

    private_constant :ResilientDispatcher
  end
end
