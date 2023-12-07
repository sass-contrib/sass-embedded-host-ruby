# frozen_string_literal: true

unless Exception.respond_to?(:to_tty?)
  # rubocop:disable Style/GlobalStdStream
  def Exception.to_tty?
    $stderr == STDERR && STDERR.tty?
  end
  # rubocop:enable Style/GlobalStdStream
end
