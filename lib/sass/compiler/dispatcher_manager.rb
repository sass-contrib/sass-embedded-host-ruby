# frozen_string_literal: true

module Sass
  class Compiler
    # The {DispatcherManager} class.
    #
    # It manages the lifecycle of {Dispatcher}.
    class DispatcherManager
      def initialize(dispatcher_class)
        @dispatcher_class = dispatcher_class
        @dispatcher = @dispatcher_class.new
        @mutex = Mutex.new
      end

      def close
        @mutex.synchronize do
          unless @dispatcher.nil?
            @dispatcher.close
            @dispatcher = nil
          end
        end
      end

      def closed?
        @mutex.synchronize do
          @dispatcher.nil?
        end
      end

      def connect(...)
        @mutex.synchronize do
          raise IOError, 'closed compiler' if @dispatcher.nil?

          @dispatcher.connect(...)
        rescue Errno::EBUSY
          @dispatcher = @dispatcher_class.new
          @dispatcher.connect(...)
        end
      end
    end

    private_constant :DispatcherManager
  end
end
