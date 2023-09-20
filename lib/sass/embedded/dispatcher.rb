# frozen_string_literal: true

module Sass
  class Embedded
    # The {Dispatcher} class.
    #
    # It dispatches messages between mutliple instances of {Host} and a single {Connection} to the compiler.
    class Dispatcher
      UINT_MAX = 0xffffffff

      def initialize
        @connection = Connection.new
        @observers = {}
        @id = 1
        @mutex = Mutex.new

        Thread.new do
          loop do
            receive_proto
          rescue IOError, Errno::EBADF, Errno::EPROTO => e
            values = @mutex.synchronize do
              @id = UINT_MAX
              @observers.values
            end
            values.each do |observer|
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

      def connect(host)
        Channel.new(self, host)
      end

      def close
        @connection.close
      end

      def closed?
        @connection.closed?
      end

      def send_proto(...)
        @connection.write(...)
      end

      private

      def receive_proto
        id, proto = @connection.read
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
          raise Errno::EPROTO, message.message
        else
          raise Errno::EPROTO
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
          @dispatcher.unsubscribe(id)
        end

        def send_proto(...)
          @dispatcher.send_proto(...)
        end
      end

      private_constant :Channel
    end

    private_constant :Dispatcher
  end
end
