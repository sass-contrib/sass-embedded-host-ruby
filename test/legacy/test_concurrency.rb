# frozen_string_literal: true

require_relative 'helper'

module Sass
  class Embedded
    class LegacyConcurrencyTest < MiniTest::Test
      include TempFileTest

      def setup
        @embedded = Embedded.new
      end

      def teardown
        @embedded.close
      end

      def render(data)
        @embedded.render(data: data).css
      end

      def test_concurrency
        10.times do
          threads = []
          10.times do |i|
            threads << Thread.new(i) do |id|
              output = @embedded.render(data: "div { width: #{id} }").css
              assert_match(/#{id}/, output)
            end
          end
          threads.each(&:join)
        end
      end
    end
  end
end
