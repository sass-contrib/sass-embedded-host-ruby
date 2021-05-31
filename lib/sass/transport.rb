# frozen_string_literal: true

require 'open3'
require 'observer'
require_relative '../../ext/embedded_sass_pb'

module Sass
  # The {::Observable} {Transport} for low level communication with
  # `dart-sass-embedded` using protocol buffers via stdio. Received messages
  # can be observed by an {Observer}.
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
      poll do
        $stderr.write @stderr.readline
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
        rescue Interrupt
          break
        rescue IOError => e
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
      message = EmbeddedProtocol::OutboundMessage.decode(proto)
      notify_observers(nil, message[message.message.to_s])
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
      varint = bits = 0
      loop do
        byte = readable.readbyte
        varint += (byte & 0x7f) << bits
        bits += 7
        break if byte <= 0x7f
      end
      varint
    end

    def write_varint(writeable, varint)
      while varint.positive?
        writeable.write ((varint > 0x7f ? 0x80 : 0) | (varint & 0x7f)).chr
        varint >>= 7
      end
    end
  end
end
