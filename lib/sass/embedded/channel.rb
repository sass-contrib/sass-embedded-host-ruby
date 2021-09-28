# frozen_string_literal: true

require_relative 'compiler'

module Sass
  class Embedded
    # The {Channel} for {Compiler} calls. Each instance creates its own
    # {Compiler}. A new {Compiler} is automatically created when the existing
    # {Compiler} runs out of unique request id.
    class Channel
      def initialize
        @mutex = Mutex.new
        @compiler = Compiler.new
      end

      def close
        @mutex.synchronize do
          @compiler.close
        end
      end

      def closed?
        @mutex.synchronize do
          @compiler.closed?
        end
      end

      def subscribe(observer)
        @mutex.synchronize do
          begin
            id = @compiler.add_observer(observer)
          rescue IOError
            @compiler = Compiler.new
            id = @compiler.add_observer(observer)
          end
          Subscription.new @compiler, observer, id
        end
      end

      # The {Subscription} between {Compiler} and {Observer}.
      class Subscription
        attr_reader :id

        def initialize(compiler, observer, id)
          @compiler = compiler
          @observer = observer
          @id = id
        end

        def unsubscribe
          @compiler.delete_observer(@observer)
        end

        def send_message(*args)
          @compiler.send_message(*args)
        end
      end

      private_constant :Subscription
    end
  end
end
