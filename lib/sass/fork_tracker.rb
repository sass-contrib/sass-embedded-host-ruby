# frozen_string_literal: true

module Sass
  # The {ForkTracker} module.
  #
  # It tracks objects that need to be closed after `Process.fork`.
  module ForkTracker
    @mutex = Mutex.new
    @hash = {}.compare_by_identity

    class << self
      def add(obj)
        @mutex.synchronize do
          @hash[obj] = true
        end
      end

      def delete(obj)
        @mutex.synchronize do
          @hash.delete(obj)
        end
      end

      def each(...)
        @mutex.synchronize do
          @hash.keys
        end.each(...)
      end
    end

    # The {CoreExt} module.
    #
    # It closes objects after `Process.fork`.
    module CoreExt
      def _fork
        pid = super
        ForkTracker.each(&:close) if pid.zero?
        pid
      end
    end

    private_constant :CoreExt

    Process.singleton_class.prepend(CoreExt)
  end

  private_constant :ForkTracker
end
