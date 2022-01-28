# frozen_string_literal: true

module Sass
  # The {Logger} module.
  module Logger
    module_function

    # The instance of a silent {Logger}.
    def silent
      Silent
    end

    # The silent {Logger}.
    module Silent
      module_function

      def warn(message, deprecation: false, span: nil, stack: nil); end

      def debug(message, span: nil); end
    end

    private_constant :Silent
  end
end
