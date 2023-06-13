# frozen_string_literal: true

require 'open3'

module Sass
  class Embedded
    # The stdio based {Connection} between the {Dispatcher} and the compiler.
    #
    # It runs the `sass --embedded` command.
    class Connection
      def initialize
        @stdin, @stdout, @stderr, @wait_thread = begin
          Open3.popen3(*CLI::COMMAND, '--embedded', chdir: __dir__)
        rescue Errno::ENOENT
          require_relative '../elf'

          raise if ELF::INTERPRETER.nil?

          Open3.popen3(ELF::INTERPRETER, *CLI::COMMAND, '--embedded', chdir: __dir__)
        end

        @stdin.binmode
        @stdout.binmode
        @stdin_mutex = Mutex.new
        @stdout_mutex = Mutex.new

        Thread.new do
          loop do
            warn(@stderr.readline, uplevel: 1)
          rescue IOError, Errno::EBADF
            break
          end
        end
      end

      def close
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

      def write(id, proto)
        @stdin_mutex.synchronize do
          Varint.write(@stdin, Varint.length(id) + proto.length)
          Varint.write(@stdin, id)
          @stdin.write(proto)
        end
      end

      def read
        @stdout_mutex.synchronize do
          length = Varint.read(@stdout)
          id = Varint.read(@stdout)
          proto = @stdout.read(length - Varint.length(id))
          return id, proto
        end
      end
    end

    private_constant :Connection
  end
end
