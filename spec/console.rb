# frozen_string_literal: true

require 'stringio'

module Console
  def capture_stdio
    stdout = $stdout
    $stdout = StringIO.new
    stderr = $stderr
    $stderr = StringIO.new

    yield

    ConsoleOutput.new $stdout.string, $stderr.string
  ensure
    $stdout = stdout
    $stderr = stderr
  end

  class ConsoleOutput
    attr_accessor :out, :err

    def initialize(out, err)
      @out = out
      @err = err
    end
  end
end
