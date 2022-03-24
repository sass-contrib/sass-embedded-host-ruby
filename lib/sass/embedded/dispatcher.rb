# frozen_string_literal: true

module Sass
  class Embedded
    # The {Dispatcher} class.
    #
    # It dispatches messages between mutliple instances of {Host} and a single {Compiler}.
    class Dispatcher
      PROTOCOL_ERROR_ID = 0xffffffff

      def initialize
        @compiler = Compiler.new
        @observers = {}
        @id = 0
        @mutex = Mutex.new

        Thread.new do
          loop do
            receive_message EmbeddedProtocol::OutboundMessage.decode @compiler.read
          rescue IOError, Errno::EBADF => e
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
        @mutex.synchronize do
          @observers.delete(id)

          close if half_closed? && @observers.empty?
        end
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
        oneof = outbound_message.message
        message = outbound_message.public_send(oneof)
        case oneof
        when :error
          half_close
          if message.id == PROTOCOL_ERROR_ID
            @observers.each_value do |observer|
              observer.public_send(oneof, message)
            end
          else
            @observers[message.id].public_send(oneof, message)
          end
        when :compile_response, :version_response
          @observers[message.id].public_send(oneof, message)
        when :log_event, :canonicalize_request, :import_request, :file_import_request, :function_call_request
          Thread.new(@observers[message.compilation_id]) do |observer|
            observer.public_send(oneof, message)
          end
        else
          raise ArgumentError, "Unknown OutboundMessage.message #{message}"
        end
      end
    end

    private_constant :Dispatcher
  end
end
