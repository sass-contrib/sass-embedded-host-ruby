# frozen_string_literal: true

module Sass
  # The abstract {Observer} for tracking state and observing messages
  # from {Transport}.
  class Observer
    def initialize(transport, id)
      raise NotImplementedError if instance_of? Observer

      @transport = transport
      @id = id
      @mutex = Mutex.new
      @condition_variable = ConditionVariable.new
      @error = nil
      @message = nil
      @transport.add_observer self
    end

    def fetch
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
  end
end
