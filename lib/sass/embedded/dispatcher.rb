# frozen_string_literal: true

module Sass
  class Embedded
    # The {Dispatcher} class.
    #
    # It dispatches messages between mutliple instances of {Host} and a single {Compiler}.
    class Dispatcher
      UINT_MAX = 0xffffffff

      def initialize
        @compiler = Compiler.new
        @observers = {}
        @id = 1
        @mutex = Mutex.new

        Thread.new do
          loop do
            receive_proto
          rescue IOError, Errno::EBADF => e
            @mutex.synchronize do
              @id = UINT_MAX
              @observers.values
            end.each do |observer|
              observer.error(e)
            end
            break
          end
        end
      end

      def subscribe(observer)
        @mutex.synchronize do
          raise Errno::EBUSY if @id == UINT_MAX

          id = @id
          @id = id.next
          @observers[id] = observer
          id
        end
      end

      def unsubscribe(id)
        @mutex.synchronize do
          @observers.delete(id)

          return unless @observers.empty?

          if @id == UINT_MAX
            close
          else
            @id = 1
          end
        end
      end

      def close
        @compiler.close
      end

      def closed?
        @compiler.closed?
      end

      def send_proto(...)
        @compiler.write(...)
      end

      private

      def receive_proto
        id, proto = @compiler.read
        case id
        when 1...UINT_MAX
          @mutex.synchronize { @observers[id] }.receive_proto(proto)
        when 0
          outbound_message = EmbeddedProtocol::OutboundMessage.decode(proto)
          oneof = outbound_message.message
          message = outbound_message.public_send(oneof)
          @mutex.synchronize { @observers[message.id] }.public_send(oneof, message)
        when UINT_MAX
          outbound_message = EmbeddedProtocol::OutboundMessage.decode(proto)
          oneof = outbound_message.message
          message = outbound_message.public_send(oneof)
          @mutex.synchronize do
            @id = UINT_MAX
            message.id == UINT_MAX ? @observers.values : [@observers[message.id]]
          end.each do |observer|
            observer.public_send(oneof, Errno::EPROTO.new(message.message))
          end
        else
          raise ArgumentError
        end
      end
    end

    private_constant :Dispatcher
  end
end
