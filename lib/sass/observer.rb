# frozen_string_literal: true

module Sass
  # The {Observer} for receiving messages from {Transport}.
  class Observer
    def initialize(transport)
      raise NotImplementedError if instance_of? Observer

      @transport = transport
      @mutex = Mutex.new
      @condition_variable = ConditionVariable.new
      @error = nil
      @message = nil
      @transport.add_observer self
    end

    def message
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
