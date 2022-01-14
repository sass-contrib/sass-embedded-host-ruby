# frozen_string_literal: true

module Sass
  # The {Logger} module.
  module Logger
    # The instance of a slient {Logger}.
    def self.slient
      @slient ||= SlientLogger.new
    end

    # The slient {Logger}.
    class Slient
      def warn(message, deprecation: false, span: nil, stack: nil); end

      def debug(message, span: nil); end
    end

    private_constant :Slient
  end
end
