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

      def connect(host)
        @mutex.synchronize do
          raise IOError, 'closed compiler' if @dispatcher.nil?

          Channel.new(@dispatcher, host)
        rescue Errno::EBUSY
          @dispatcher = @dispatcher_class.new
          Channel.new(@dispatcher, host)
        end
      end

      # The {Channel} between {Dispatcher} and {Host}.
      class Channel
        attr_reader :id

        def initialize(dispatcher, host)
          @dispatcher = dispatcher
          @id = @dispatcher.subscribe(host)
        end

        def disconnect
          @dispatcher.unsubscribe(@id)
        end

        def error(...)
          @dispatcher.error(...)
        end

        def send_proto(...)
          @dispatcher.send_proto(...)
        end
      end

      private_constant :Channel
    end

    private_constant :DispatcherManager
  end
end
