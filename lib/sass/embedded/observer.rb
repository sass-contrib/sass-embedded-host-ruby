# frozen_string_literal: true

module Sass
  class Embedded
    # The {Observer} module for communicating with {Compiler}.
    module Observer
      def initialize(channel)
        @mutex = Mutex.new
        @condition_variable = ConditionVariable.new
        @error = nil
        @message = nil

        @subscription = channel.subscribe(self)
      end

      def receive_message
        @mutex.synchronize do
          @condition_variable.wait(@mutex) if @error.nil? && @message.nil?
        end

        raise @error unless @error.nil?

        @message
      end

      def update(error, message)
        @subscription.unsubscribe

        @mutex.synchronize do
          @error = error
          @message = message
          @condition_variable.broadcast
        end
      end

      private

      def id
        @subscription.id
      end

      def send_message(*args)
        @subscription.send_message(*args)
      end
    end

    private_constant :Observer
  end
end
