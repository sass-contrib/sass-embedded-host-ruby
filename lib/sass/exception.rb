# frozen_string_literal: true

unless Exception.respond_to?(:to_tty?)
  def Exception.to_tty?
    $stderr == STDERR && STDERR.tty? # rubocop:disable Style/GlobalStdStream
  end
end
