# frozen_string_literal: true

require 'open3'
require 'observer'
require_relative '../../ext/embedded_sass_pb'

module Sass
  # The interface for communicating with dart-sass-embedded.
  # It handles message serialization and deserialization as well as
  # tracking concurrent request and response
  class Transport
    include Observable

    DART_SASS_EMBEDDED = File.absolute_path(
      "../../ext/sass_embedded/dart-sass-embedded#{Sass::Platform::OS == 'windows' ? '.bat' : ''}", __dir__
    )

    PROTOCOL_ERROR_ID = 4_294_967_295

    def initialize
      @stdin_semaphore = Mutex.new
      @observerable_semaphore = Mutex.new
      @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(DART_SASS_EMBEDDED)
      watch_stdout
      watch_stderr
    end

    def send(req, id)
      mutex = Mutex.new
      resource = ConditionVariable.new

      req_kind = req.class.name.split('::').last.gsub(/\B(?=[A-Z])/, '_').downcase

      message = Sass::EmbeddedProtocol::InboundMessage.new(req_kind => req)

      error = nil
      res = nil

      @observerable_semaphore.synchronize do
        MessageObserver.new self, id do |e, r|
          mutex.synchronize do
            error = e
            res = r

            resource.signal
          end
        end
      end

      mutex.synchronize do
        write message.to_proto

        resource.wait(mutex)
      end

      raise error if error

      res
    end

    def close
      delete_observers
      @stdin.close unless @stdin.closed?
      @stdout.close unless @stdout.closed?
      @stderr.close unless @stderr.closed?
      nil
    end

    private

    def watch_stdout
      Thread.new do
        loop do
          bits = length = 0
          loop do
            byte = @stdout.readbyte
            length += (byte & 0x7f) << bits
            bits += 7
            break if byte <= 0x7f
          end
          changed
          payload = @stdout.read length
          @observerable_semaphore.synchronize do
            notify_observers nil, Sass::EmbeddedProtocol::OutboundMessage.decode(payload)
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

    def watch_stderr
      Thread.new do
        loop do
          warn @stderr.read
        rescue Interrupt
          break
        rescue IOError => e
          @observerable_semaphore.synchronize do
            notify_observers e, nil
          end
          close
          break
        end
      end
    end

    def write(proto)
      @stdin_semaphore.synchronize do
        length = proto.length
        while length.positive?
          @stdin.write ((length > 0x7f ? 0x80 : 0) | (length & 0x7f)).chr
          length >>= 7
        end
        @stdin.write proto
      end
    end

    # The observer used to listen on messages from stdout, check if id
    # matches the given request id, and yield back to the given block.
    class MessageObserver
      def initialize(obs, id, &block)
        @obs = obs
        @id = id
        @block = block
        @obs.add_observer self
      end

      def update(error, message)
        if error
          @obs.delete_observer self
          @block.call error, nil
        elsif message.error&.id == Sass::Transport::PROTOCOL_ERROR_ID
          @obs.delete_observer self
          @block.call Sass::ProtocolError.new(message.error.message), nil
        else
          res = message[message.message.to_s]
          if (res['compilation_id'] || res['id']) == @id
            @obs.delete_observer self
            @block.call error, res
          end
        end
      end
    end
  end
end
