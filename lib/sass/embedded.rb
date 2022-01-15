# frozen_string_literal: true

require_relative 'compile_error'
require_relative 'compile_result'
require_relative 'importer_result'
require_relative 'embedded/channel'
require_relative 'embedded/compile_context'
require_relative 'embedded/render'
require_relative 'embedded/url'
require_relative 'embedded/version'
require_relative 'embedded/version_context'
require_relative 'logger'

module Sass
  # The {Embedded} host for using dart-sass-embedded. Each instance creates
  # its own {Channel}.
  #
  # @example
  #   embedded = Sass::Embedded.new
  #   result = embedded.compile_string('h1 { font-size: 40px; }')
  #   result = embedded.compile('style.scss')
  #   embedded.close
  class Embedded
    def initialize
      @channel = Channel.new
    end

    # The {Embedded#compile} method.
    #
    # @return [CompileResult]
    # @raise [CompileError]
    # @raise [ProtocolError]
    def compile(path,
                load_paths: [],

                source_map: false,
                style: :expanded,

                functions: {},
                importers: [],

                alert_ascii: false,
                alert_color: $stderr.tty?,
                logger: nil,
                quiet_deps: false,
                verbose: false)

      raise ArgumentError, 'path must be set' if path.nil?

      message = CompileContext.new(@channel,
                                   path: path,
                                   source: nil,
                                   importer: nil,
                                   load_paths: load_paths,
                                   syntax: nil,
                                   url: nil,
                                   source_map: source_map,
                                   style: style,
                                   functions: functions,
                                   importers: importers,
                                   alert_color: alert_color,
                                   alert_ascii: alert_ascii,
                                   logger: logger,
                                   quiet_deps: quiet_deps,
                                   verbose: verbose).receive_message

      raise CompileError.from_proto(message.failure) if message.failure

      CompileResult.from_proto(message.success)
    end

    # The {Embedded#compile_string} method.
    #
    # @return [CompileResult]
    # @raise [CompileError]
    # @raise [ProtocolError]
    def compile_string(source,
                       importer: nil,
                       load_paths: [],
                       syntax: :scss,
                       url: nil,

                       source_map: false,
                       style: :expanded,

                       functions: {},
                       importers: [],

                       alert_ascii: false,
                       alert_color: $stderr.tty?,
                       logger: nil,
                       quiet_deps: false,
                       verbose: false)
      raise ArgumentError, 'source must be set' if source.nil?

      message = CompileContext.new(@channel,
                                   path: nil,
                                   source: source,
                                   importer: importer,
                                   load_paths: load_paths,
                                   syntax: syntax,
                                   url: url,
                                   source_map: source_map,
                                   style: style,
                                   functions: functions,
                                   importers: importers,
                                   alert_color: alert_color,
                                   alert_ascii: alert_ascii,
                                   logger: logger,
                                   quiet_deps: quiet_deps,
                                   verbose: verbose).receive_message

      raise CompileError.from_proto(message.failure) if message.failure

      CompileResult.from_proto(message.success)
    end

    # The {Embedded#info} method.
    #
    # @raise [ProtocolError]
    def info
      @info ||= VersionContext.new(@channel).receive_message
    end

    def close
      @channel.close
    end

    def closed?
      @channel.closed?
    end
  end
end
