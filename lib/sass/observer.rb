# frozen_string_literal: true

module Sass
  # The {Observer} module for receiving messages from {Transport}.
  module Observer
    def initialize(transport)
      @transport = transport
      @mutex = Mutex.new
      @condition_variable = ConditionVariable.new
      @error = nil
      @message = nil
      @transport.add_observer self
    end

    def receive_message
      @mutex.synchronize do
        @condition_variable.wait(@mutex) if @error.nil? && @message.nil?
      end

      raise @error unless @error.nil?

      @message
    end

    def update(error, message)
      @transport.delete_observer self
      @mutex.synchronize do
        @error = error
        @message = message
        @condition_variable.broadcast
      end
    end

    private

    def send_message(message)
      @transport.send_message(message)
    end
  end
end
