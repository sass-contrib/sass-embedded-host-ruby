# frozen_string_literal: true

require_relative 'canonicalize_context'
require_relative 'compile_result'
require_relative 'compiler/connection'
require_relative 'compiler/dispatcher'
require_relative 'compiler/dispatcher_manager'
require_relative 'compiler/host'
require_relative 'compiler/varint'
require_relative 'embedded_protocol'
require_relative 'exception'
require_relative 'fork_tracker'
require_relative 'logger/silent'
require_relative 'logger/source_location'
require_relative 'logger/source_span'
require_relative 'serializer'
require_relative 'value'

module Sass
  # The {Compiler} for using dart-sass. Each instance creates its own
  # communication {Dispatcher} with a dedicated compiler process.
  #
  # @example
  #   sass = Sass::Compiler.new
  #   result = sass.compile_string('h1 { font-size: 40px; }')
  #   result = sass.compile('style.scss')
  #   sass.close
  class Compiler
    def initialize
      @dispatcher = DispatcherManager.new(Dispatcher)
    end

    # Compiles the Sass file at +path+ to CSS.
    # @param path [String]
    # @param load_paths [Array<String>] Paths in which to look for stylesheets loaded by rules like
    #   {@use}[https://sass-lang.com/documentation/at-rules/use/] and {@import}[https://sass-lang.com/documentation/at-rules/import/].
    # @param charset [Boolean] By default, if the CSS document contains non-ASCII characters, Sass adds a +@charset+
    #   declaration (in expanded output mode) or a byte-order mark (in compressed mode) to indicate its encoding to
    #   browsers or other consumers. If +charset+ is +false+, these annotations are omitted.
    # @param source_map [Boolean] Whether or not Sass should generate a source map.
    # @param source_map_include_sources [Boolean] Whether Sass should include the sources in the generated source map.
    # @param style [String, Symbol] The OutputStyle of the compiled CSS.
    # @param functions [Hash<String, Proc>] Additional built-in Sass functions that are available in all stylesheets.
    # @param importers [Array<Object>] Custom importers that control how Sass resolves loads from rules like
    #   {@use}[https://sass-lang.com/documentation/at-rules/use/] and {@import}[https://sass-lang.com/documentation/at-rules/import/].
    # @param alert_ascii [Boolean] If this is +true+, the compiler will exclusively use ASCII characters in its error
    #   and warning messages. Otherwise, it may use non-ASCII Unicode characters as well.
    # @param alert_color [Boolean] If this is +true+, the compiler will use ANSI color escape codes in its error and
    #   warning messages. If it's +false+, it won't use these. If it's +nil+, the compiler will determine whether or
    #   not to use colors depending on whether the user is using an interactive terminal.
    # @param logger [Object] An object to use to handle warnings and/or debug messages from Sass.
    # @param quiet_deps [Boolean] If this option is set to +true+, Sass won’t print warnings that are caused by
    #   dependencies. A “dependency” is defined as any file that’s loaded through +load_paths+ or +importer+.
    #   Stylesheets that are imported relative to the entrypoint are not considered dependencies.
    # @param verbose [Boolean] By default, Dart Sass will print only five instances of the same deprecation warning per
    #   compilation to avoid deluging users in console noise. If you set verbose to +true+, it will instead print every
    #   deprecation warning it encounters.
    # @return [CompileResult]
    # @raise [ArgumentError, CompileError]
    # @see https://sass-lang.com/documentation/js-api/functions/compile/
    def compile(path,
                load_paths: [],

                charset: true,
                source_map: false,
                source_map_include_sources: false,
                style: :expanded,

                functions: {},
                importers: [],

                alert_ascii: false,
                alert_color: nil,
                logger: nil,
                quiet_deps: false,
                verbose: false)
      raise ArgumentError, 'path must be set' if path.nil?

      Host.new(@dispatcher).compile_request(
        path:,
        source: nil,
        importer: nil,
        load_paths:,
        syntax: nil,
        url: nil,
        charset:,
        source_map:,
        source_map_include_sources:,
        style:,
        functions:,
        importers:,
        alert_color:,
        alert_ascii:,
        logger:,
        quiet_deps:,
        verbose:
      )
    end

    # Compiles a stylesheet whose contents is +source+ to CSS.
    # @param source [String]
    # @param importer [Object] The importer to use to handle loads that are relative to the entrypoint stylesheet.
    # @param load_paths [Array<String>] Paths in which to look for stylesheets loaded by rules like
    #   {@use}[https://sass-lang.com/documentation/at-rules/use/] and {@import}[https://sass-lang.com/documentation/at-rules/import/].
    # @param syntax [String, Symbol] The Syntax to use to parse the entrypoint stylesheet.
    # @param url [String] The canonical URL of the entrypoint stylesheet. If this is passed along with +importer+, it's
    #   used to resolve relative loads in the entrypoint stylesheet.
    # @param charset [Boolean] By default, if the CSS document contains non-ASCII characters, Sass adds a +@charset+
    #   declaration (in expanded output mode) or a byte-order mark (in compressed mode) to indicate its encoding to
    #   browsers or other consumers. If +charset+ is +false+, these annotations are omitted.
    # @param source_map [Boolean] Whether or not Sass should generate a source map.
    # @param source_map_include_sources [Boolean] Whether Sass should include the sources in the generated source map.
    # @param style [String, Symbol] The OutputStyle of the compiled CSS.
    # @param functions [Hash<String, Proc>] Additional built-in Sass functions that are available in all stylesheets.
    # @param importers [Array<Object>] Custom importers that control how Sass resolves loads from rules like
    #   {@use}[https://sass-lang.com/documentation/at-rules/use/] and {@import}[https://sass-lang.com/documentation/at-rules/import/].
    # @param alert_ascii [Boolean] If this is +true+, the compiler will exclusively use ASCII characters in its error
    #   and warning messages. Otherwise, it may use non-ASCII Unicode characters as well.
    # @param alert_color [Boolean] If this is +true+, the compiler will use ANSI color escape codes in its error and
    #   warning messages. If it's +false+, it won't use these. If it's +nil+, the compiler will determine whether or
    #   not to use colors depending on whether the user is using an interactive terminal.
    # @param logger [Object] An object to use to handle warnings and/or debug messages from Sass.
    # @param quiet_deps [Boolean] If this option is set to +true+, Sass won’t print warnings that are caused by
    #   dependencies. A “dependency” is defined as any file that’s loaded through +load_paths+ or +importer+.
    #   Stylesheets that are imported relative to the entrypoint are not considered dependencies.
    # @param verbose [Boolean] By default, Dart Sass will print only five instances of the same deprecation warning per
    #   compilation to avoid deluging users in console noise. If you set verbose to +true+, it will instead print every
    #   deprecation warning it encounters.
    # @return [CompileResult]
    # @raise [ArgumentError, CompileError]
    # @see https://sass-lang.com/documentation/js-api/functions/compilestring/
    def compile_string(source,
                       importer: nil,
                       load_paths: [],
                       syntax: :scss,
                       url: nil,

                       charset: true,
                       source_map: false,
                       source_map_include_sources: false,
                       style: :expanded,

                       functions: {},
                       importers: [],

                       alert_ascii: false,
                       alert_color: nil,
                       logger: nil,
                       quiet_deps: false,
                       verbose: false)
      raise ArgumentError, 'source must be set' if source.nil?

      Host.new(@dispatcher).compile_request(
        path: nil,
        source:,
        importer:,
        load_paths:,
        syntax:,
        url:,
        charset:,
        source_map:,
        source_map_include_sources:,
        style:,
        functions:,
        importers:,
        alert_color:,
        alert_ascii:,
        logger:,
        quiet_deps:,
        verbose:
      )
    end

    # @return [String] Information about the Sass implementation.
    # @see https://sass-lang.com/documentation/js-api/variables/info/
    def info
      @info ||= <<~INFO.freeze
        sass-embedded\t#{Embedded::VERSION}\t(Embedded Host)\t[Ruby]
        #{Host.new(@dispatcher).version_request}
      INFO
    end

    def close
      @dispatcher.close
    end

    def closed?
      @dispatcher.closed?
    end
  end
end
