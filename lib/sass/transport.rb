# frozen_string_literal: true

require 'open3'
require 'observer'
require_relative '../../ext/embedded_sass_pb'

module Sass
  # The interface for communicating with dart-sass-embedded.
  # It handles message serialization and deserialization
  class Transport
    include Observable

    DART_SASS_EMBEDDED = File.absolute_path(
      "../../ext/sass_embedded/dart-sass-embedded#{Platform::OS == 'windows' ? '.bat' : ''}", __dir__
    )

    PROTOCOL_ERROR_ID = 4_294_967_295

    ONEOF_MESSAGE = EmbeddedProtocol::InboundMessage
                    .descriptor
                    .lookup_oneof('message')
                    .collect do |field_descriptor|
      [field_descriptor.subtype, field_descriptor.name]
    end.to_h

    def initialize
      @observerable_mutex = Mutex.new
      @stdin_mutex = Mutex.new
      @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(DART_SASS_EMBEDDED)
      pipe @stderr, $stderr
      receive
    end

    def add_observer(*args)
      @observerable_mutex.synchronize do
        super(*args)
      end
    end

    def send(message)
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

    def receive
      Thread.new do
        loop do
          bits = length = 0
          loop do
            byte = @stdout.readbyte
            length += (byte & 0x7f) << bits
            bits += 7
            break if byte <= 0x7f
          end
          payload = @stdout.read length
          message = EmbeddedProtocol::OutboundMessage.decode payload
          @observerable_mutex.synchronize do
            changed
            notify_observers nil, message[message.message.to_s]
          end
        rescue Interrupt
          break
        rescue IOError => e
          notify_observers e, nil
          close
          break
        end
      end
    end

    def pipe(readable, writeable)
      Thread.new do
        loop do
          writeable.write readable.read
        rescue Interrupt
          break
        rescue IOError => e
          @observerable_mutex.synchronize do
            notify_observers e, nil
          end
          close
          break
        end
      end
    end

    def write(payload)
      @stdin_mutex.synchronize do
        length = payload.length
        while length.positive?
          @stdin.write ((length > 0x7f ? 0x80 : 0) | (length & 0x7f)).chr
          length >>= 7
        end
        @stdin.write payload
      end
    end
  end
end
