# frozen_string_literal: true

module Sass
  # The {Observer} for {Embedded#info}.
  class Info < Observer
    def initialize(transport, id)
      super(transport, id)
      @transport.send EmbeddedProtocol::InboundMessage::VersionRequest.new(id: @id)
    end

    def update(error, message)
      raise error unless error.nil?

      case message
      when EmbeddedProtocol::ProtocolError
        raise ProtocolError, message.message
      when EmbeddedProtocol::OutboundMessage::VersionResponse
        return unless message.id == @id

        Thread.new do
          super(nil, message)
        end
      end
    rescue StandardError => e
      Thread.new do
        super(e, nil)
      end
    end
  end
end
