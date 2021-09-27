# frozen_string_literal: true

require_relative '../embedded_protocol'
require_relative 'observer'

module Sass
  class Embedded
    # The {Observer} for {Embedded#info}.
    class VersionContext
      include Observer

      def initialize(channel)
        super(channel)

        send_message EmbeddedProtocol::InboundMessage::VersionRequest.new(id: id)
      end

      def update(error, message)
        raise error unless error.nil?

        case message
        when EmbeddedProtocol::OutboundMessage::VersionResponse
          return unless message.id == id

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
end
