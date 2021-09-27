# frozen_string_literal: true

require 'open3'
require 'observer'
require_relative 'compiler'
require_relative 'error'
require_relative 'protocol'

module Sass
  class Embedded
    # The {::Observable} {Transport} for low level communication with
    # `dart-sass-embedded` using protocol buffers via stdio. Received messages
    # can be observed by an {Observer}.
    class Transport
      include Observable

      ONEOF_MESSAGE = EmbeddedProtocol::InboundMessage
                      .descriptor
                      .lookup_oneof('message')
                      .collect do |field_descriptor|
        [field_descriptor.subtype, field_descriptor.name]
      end.to_h

      private_constant :ONEOF_MESSAGE

      def initialize
        @observerable_mutex = Mutex.new
        @stdin_mutex = Mutex.new
        @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(Compiler::PATH)

        [@stdin, @stdout].each(&:binmode)

        poll do
          warn(@stderr.readline, uplevel: 1)
        end
        poll do
          receive_proto read
        end
      end

      def add_observer(*args)
        @observerable_mutex.synchronize do
          super(*args)
        end
      end

      def send_message(message)
        write EmbeddedProtocol::InboundMessage.new(
          ONEOF_MESSAGE[message.class.descriptor] => message
        ).to_proto
      end

      def close
        delete_observers
        @stdin.close unless @stdin.closed?
        @stdout.close unless @stdout.closed?
        @stderr.close unless @stderr.closed?
        nil
      end

      def closed?
        @stdin.closed?
      end

      private

      def poll
        Thread.new do
          loop do
            yield
          rescue StandardError => e
            notify_observers(e, nil)
            close
            break
          end
        end
      end

      def notify_observers(*args)
        @observerable_mutex.synchronize do
          changed
          super(*args)
        end
      end

      def receive_proto(proto)
        payload = EmbeddedProtocol::OutboundMessage.decode(proto)
        message = payload[payload.message.to_s]
        case message
        when EmbeddedProtocol::ProtocolError
          raise ProtocolError, message.message
        else
          notify_observers(nil, message)
        end
      end

      def read
        length = read_varint(@stdout)
        @stdout.read(length)
      end

      def write(payload)
        @stdin_mutex.synchronize do
          write_varint(@stdin, payload.length)
          @stdin.write payload
        end
      end

      def read_varint(readable)
        value = bits = 0
        loop do
          byte = readable.readbyte
          value |= (byte & 0x7f) << bits
          bits += 7
          break if byte < 0x80
        end
        value
      end

      def write_varint(writeable, value)
        bytes = []
        until value < 0x80
          bytes << (0x80 | (value & 0x7f))
          value >>= 7
        end
        bytes << value
        writeable.write bytes.pack('C*')
      end
    end
  end
end
