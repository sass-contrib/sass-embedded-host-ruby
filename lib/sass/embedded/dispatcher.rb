# frozen_string_literal: true

module Sass
  class Embedded
    # The {Dispatcher} class.
    #
    # It dispatches messages between mutliple instances of {Host} and a single {Compiler}.
    class Dispatcher
      PROTOCOL_ERROR_ID = 4_294_967_295

      def initialize
        @compiler = Compiler.new
        @observers = {}
        @id = 0
        @mutex = Mutex.new

        Thread.new do
          loop do
            receive_message EmbeddedProtocol::OutboundMessage.decode @compiler.read
          rescue IOError => e
            half_close
            @observers.each_value do |observer|
              observer.error e
            end
            break
          end
        end
      end

      def subscribe(observer)
        @mutex.synchronize do
          raise EOFError if half_closed?

          id = @id
          @id = id.next
          @observers[id] = observer
          id
        end
      end

      def unsubscribe(id)
        @observers.delete(id)

        close if half_closed? && @observers.empty?
      end

      def close
        @compiler.close
      end

      def closed?
        @compiler.closed?
      end

      def send_message(inbound_message)
        @compiler.write(inbound_message.to_proto)
      end

      private

      def half_close
        @mutex.synchronize do
          @id = PROTOCOL_ERROR_ID
        end
      end

      def half_closed?
        @id == PROTOCOL_ERROR_ID
      end

      def receive_message(outbound_message)
        message = outbound_message.send(outbound_message.message)

        case outbound_message.message
        when :error
          half_close
          @observers[message.id]&.send(outbound_message.message, message)
        when :compile_response, :version_response
          @observers[message.id].send(outbound_message.message, message)
        when :log_event, :canonicalize_request, :import_request, :file_import_request, :function_call_request
          Thread.new(@observers[message.compilation_id]) do |observer|
            observer.send(outbound_message.message, message)
          end
        else
          raise ArgumentError, "Unknown OutboundMessage.message #{message}"
        end
      end
    end

    private_constant :Dispatcher
  end
end
