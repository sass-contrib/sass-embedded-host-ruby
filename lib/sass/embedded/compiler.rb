# frozen_string_literal: true

require 'observer'
require 'open3'

module Sass
  class Embedded
    # The {::Observable} {Compiler} for low level communication with
    # `dart-sass-embedded` using protocol buffers via stdio. Received messages
    # can be observed by an {Observer}.
    class Compiler
      include Observable

      PATH = File.absolute_path(
        "../../../ext/sass/sass_embedded/dart-sass-embedded#{Gem.win_platform? ? '.bat' : ''}", __dir__
      )

      PROTOCOL_ERROR_ID = 4_294_967_295

      def initialize
        @observerable_mutex = Mutex.new
        @id = 0
        @stdin_mutex = Mutex.new
        @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(PATH)

        [@stdin, @stdout].each(&:binmode)

        poll do
          warn(@stderr.readline, uplevel: 1)
        end
        poll do
          receive_message Protofier.from_proto_message read
        end
      end

      def add_observer(*args)
        @observerable_mutex.synchronize do
          raise ProtocolError, 'half-closed compiler' if half_closed?

          super(*args)

          id = @id
          @id = @id.next
          id
        end
      end

      def delete_observer(*args)
        @observerable_mutex.synchronize do
          super(*args)

          close if half_closed? && count_observers.zero?
        end
      end

      def send_message(message)
        write Protofier.to_proto_message message
      end

      def close
        delete_observers

        @stdin_mutex.synchronize do
          @stdin.close unless @stdin.closed?
          @stdout.close unless @stdout.closed?
          @stderr.close unless @stderr.closed?
        end

        @wait_thread.value
      end

      def closed?
        @stdin_mutex.synchronize do
          @stdin.closed?
        end
      end

      private

      def half_closed?
        @id == PROTOCOL_ERROR_ID
      end

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

      def receive_message(message)
        case message
        when EmbeddedProtocol::ProtocolError
          raise ProtocolError, message.message
        else
          notify_observers(nil, message)
        end
      end

      def read
        length = Varint.read(@stdout)
        @stdout.read(length)
      end

      def write(payload)
        @stdin_mutex.synchronize do
          Varint.write(@stdin, payload.length)
          @stdin.write(payload)
        end
      end
    end

    private_constant :Compiler
  end
end
