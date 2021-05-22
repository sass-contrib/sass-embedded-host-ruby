# frozen_string_literal: true

require "open3"
require "observer"
require_relative "../../../ext/sass_embedded/embedded_sass_pb.rb"

module Sass
  module Embedded
    class Transport

      include Observable

      DART_SASS_EMBEDDED = File.absolute_path("../../../ext/sass_embedded/sass_embedded/dart-sass-embedded#{Sass::Platform::OS == 'windows' ? '.bat' : ''}", __dir__)

      PROTOCOL_ERROR_ID = 4294967295

      def initialize
        @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(DART_SASS_EMBEDDED)
        @stdin_semaphore = Mutex.new
        @observerable_semaphore = Mutex.new

        Thread.new do
          loop do
            begin
              bits = length = 0
              loop do
                byte = @stdout.readbyte
                length += (byte & 0x7f) << bits
                bits += 7
                break if byte <= 0x7f
              end
              changed
              payload = @stdout.read length
              @observerable_semaphore.synchronize {
                notify_observers nil, Sass::EmbeddedProtocol::OutboundMessage.decode(payload)
              }
            rescue Interrupt
              break
            rescue IOError, EOFError => error
              notify_observers error, nil
              close
              break
            end
          end
        end

        Thread.new do
          loop do
            begin
              $stderr.puts @stderr.read
            rescue Interrupt
              break
            rescue IOError, EOFErrorr => error
              @observerable_semaphore.synchronize {
                notify_observers error, nil
              }
              close
              break
            end
          end
        end
      end

      def send req, id
        mutex = Mutex.new
        resource = ConditionVariable.new

        req_name = req.class.name.split('::').last.gsub(/\B(?=[A-Z])/, "_").downcase

        message = Sass::EmbeddedProtocol::InboundMessage.new(req_name.to_sym => req)

        error = nil
        res = nil

        @observerable_semaphore.synchronize {
          MessageObserver.new self, id do |_error, _res|
            mutex.synchronize {
              error = _error
              res = _res

              resource.signal
            }
          end
        }

        mutex.synchronize {
          write message.to_proto

          resource.wait(mutex)
        }

        raise error if error
        res
      end

      def close
        begin
          delete_observers
          @stdin.close
          @stdout.close
          @stderr.close
        rescue
        end
      end

      private

      def write proto
        @stdin_semaphore.synchronize {
          length = proto.length
          while length > 0
            @stdin.write ((length > 0x7f ? 0x80 : 0) | (length & 0x7f)).chr
            length >>= 7
          end
          @stdin.write proto
        }
      end
    end

    private

    class MessageObserver
      def initialize obs, id, &block
        @obs = obs
        @id = id
        @block = block
        @obs.add_observer self
      end

      def update error, message
        if error
          @obs.delete_observer self
          @block.call error, nil
        elsif message.error&.id == Sass::Embedded::Transport::PROTOCOL_ERROR_ID
          @obs.delete_observer self
          @block.call Sass::ProtocolError.new(message.error.message), nil
        else
          res = message[message.message.to_s]
          if (res['compilation_id'] == @id || res['id'] == @id)
            @obs.delete_observer self
            @block.call error, res
          end
        end
      end
    end
  end
end
