# frozen_string_literal: true

require 'base64'
require 'json'
require 'pathname'
require 'uri'

# The Sass module.
#
# This communicates with Embedded Dart Sass using the Embedded Sass protocol.
module Sass
  class << self
    # @deprecated
    # The global {.include_paths} for Sass files. This is meant for plugins and
    # libraries to register the paths to their Sass stylesheets to that they may
    # be included via `@import` or `@use`. This include path is used by every
    # instance of {Sass::Embedded}. They are lower-precedence than any include
    # paths passed in via the `include_paths` option.
    #
    # If the `SASS_PATH` environment variable is set,
    # the initial value of `include_paths` will be initialized based on that.
    # The variable should be a colon-separated list of path names
    # (semicolon-separated on Windows).
    #
    # @example
    #   Sass.include_paths << File.dirname(__FILE__) + '/sass'
    # @return [Array]
    def include_paths
      Embedded.include_paths
    end

    # @deprecated
    # The global {.render} method. This instantiates a global {Embedded} instance
    # and calls {Embedded#render}.
    #
    # See {Embedded#render} for supported options.
    #
    # @example
    #   Sass.render(data: 'h1 { font-size: 40px; }')
    # @example
    #   Sass.render(file: 'style.css')
    # @return [Result]
    # @raise [RenderError]
    def render(**kwargs)
      instance.render(**kwargs)
    end
  end

  # The {Embedded} host for using dart-sass-embedded. Each instance creates
  # its own {Channel}.
  #
  # @example
  #   embedded = Sass::Embedded.new
  #   result = embedded.compile_string('h1 { font-size: 40px; }')
  #   result = embedded.compile('style.scss')
  #   embedded.close
  class Embedded
    # @deprecated
    def self.include_paths
      @include_paths ||= if ENV['SASS_PATH']
                           ENV['SASS_PATH'].split(File::PATH_SEPARATOR)
                         else
                           []
                         end
    end

    # @deprecated
    # The {Embedded#render} method.
    #
    # See {file:README.md#options} for supported options.
    #
    # @return [RenderResult]
    # @raise [RenderError]
    def render(data: nil,
               file: nil,
               indented_syntax: false,
               include_paths: [],
               output_style: :expanded,
               indent_type: :space,
               indent_width: 2,
               linefeed: :lf,
               source_map: false,
               out_file: nil,
               omit_source_map_url: false,
               source_map_contents: false,
               source_map_embed: false,
               source_map_root: '',
               functions: {},
               importer: [])
      start = now

      raise ArgumentError, 'either data or file must be set' if file.nil? && data.nil?

      indent_type = parse_indent_type(indent_type)
      indent_width = parse_indent_width(indent_width)
      linefeed = parse_linefeed(linefeed)

      load_paths = include_paths + Embedded.include_paths

      source_map_option = source_map.is_a?(String) || (source_map == true && !out_file.nil?)

      begin
        compile_result = if data
                           compile_string(data, load_paths: load_paths,
                                                syntax: indented_syntax ? :indented : :scss,
                                                url: (Url.path_to_file_url(File.absolute_path(file)) unless file.nil?),
                                                source_map: source_map_option,
                                                source_map_include_sources: source_map_contents,
                                                style: output_style,
                                                functions: functions,
                                                importers: importer.map do |legacy_importer|
                                                             LegacyImporter.new(legacy_importer, file)
                                                           end)
                         else
                           compile(file, load_paths: load_paths,
                                         source_map: source_map_option,
                                         source_map_include_sources: source_map_contents,
                                         style: output_style,
                                         functions: functions,
                                         importers: importer.map do |legacy_importer|
                                                      LegacyImporter.new(legacy_importer, file)
                                                    end)
                         end
      rescue CompileError => e
        raise RenderError.new(
          e.message,
          e.full_message,
          if e.span.nil?
            nil
          elsif e.span.url.nil?
            'stdin'
          else
            Url.file_url_to_path(e.span.url)
          end,
          e.span.start.line + 1,
          e.span.start.column + 1,
          1
        )
      end

      map, source_map = post_process_map(map: compile_result.source_map,
                                         file: file,
                                         out_file: out_file,
                                         source_map: source_map,
                                         source_map_root: source_map_root)

      css = post_process_css(css: compile_result.css,
                             indent_type: indent_type,
                             indent_width: indent_width,
                             linefeed: linefeed,
                             map: map,
                             out_file: out_file,
                             omit_source_map_url: omit_source_map_url,
                             source_map: source_map,
                             source_map_embed: source_map_embed)

      finish = now

      stats = RenderResultStats.new(file.nil? ? 'data' : file, start, finish, finish - start)

      RenderResult.new(css, map, stats)
    end

    # @deprecated
    # The {RenderResult} of {Embedded#render}.
    class RenderResult
      attr_reader :css, :map, :stats

      def initialize(css, map, stats)
        @css = css
        @map = map
        @stats = stats
      end
    end

    # @deprecated
    # The {RenderResultStats} of {Embedded#render}.
    class RenderResultStats
      attr_reader :entry, :start, :end, :duration

      def initialize(entry, start, finish, duration)
        @entry = entry
        @start = start
        @end = finish
        @duration = duration
      end
    end

    # @deprecated
    # The {RenderError} raised by {Embedded#render}.
    class RenderError < StandardError
      attr_reader :formatted, :file, :line, :column, :status

      def initialize(message, formatted, file, line, column, status)
        super(message)
        @formatted = formatted
        @file = file
        @line = line
        @column = column
        @status = status
      end

      def backtrace
        return nil if super.nil?

        ["#{@file}:#{@line}:#{@column}"] + super
      end
    end

    private

    # @deprecated
    def post_process_map(map:,
                         file:,
                         out_file:,
                         source_map:,
                         source_map_root:)
      return if map.nil? || map.empty?

      map_data = JSON.parse(map)

      map_data['sourceRoot'] = source_map_root

      source_map_path = if source_map.is_a? String
                          source_map
                        else
                          "#{out_file}.map"
                        end

      source_map_dir = File.dirname(source_map_path)

      if out_file
        map_data['file'] = relative_path(source_map_dir, out_file)
      elsif file
        ext = File.extname(file)
        map_data['file'] = "#{file[0..(ext.empty? ? -1 : -ext.length - 1)]}.css"
      else
        map_data['file'] = 'stdin.css'
      end

      map_data['sources'].map! do |source|
        if source.start_with? 'file://'
          path = Url.file_url_to_path(source)
          relative_path(source_map_dir, path)
        else
          source
        end
      end

      [-JSON.generate(map_data), source_map_path]
    end

    # @deprecated
    def post_process_css(css:,
                         indent_type:,
                         indent_width:,
                         linefeed:,
                         map:,
                         omit_source_map_url:,
                         out_file:,
                         source_map:,
                         source_map_embed:)
      css = +css
      if indent_width != 2 || indent_type.to_sym != :space
        indent = indent_type * indent_width
        css.gsub!(/^ +/) do |space|
          indent * (space.length / 2)
        end
      end
      css.gsub!("\n", linefeed) if linefeed != "\n"

      unless map.nil? || omit_source_map_url == true
        url = if source_map_embed
                "data:application/json;base64,#{Base64.strict_encode64(map)}"
              elsif out_file
                relative_path(File.dirname(out_file), source_map)
              else
                source_map
              end
        css += "#{linefeed}#{linefeed}/*# sourceMappingURL=#{url} */"
      end

      -css
    end

    # @deprecated
    def parse_indent_type(indent_type)
      case indent_type.to_sym
      when :space
        ' '
      when :tab
        "\t"
      else
        raise ArgumentError, 'indent_type must be one of :space, :tab'
      end
    end

    # @deprecated
    def parse_indent_width(indent_width)
      raise ArgumentError, 'indent_width must be an integer' unless indent_width.is_a? Integer
      raise RangeError, 'indent_width must be in between 0 and 10 (inclusive)' unless indent_width.between? 0, 10

      indent_width
    end

    # @deprecated
    def parse_linefeed(linefeed)
      case linefeed.to_sym
      when :lf
        "\n"
      when :lfcr
        "\n\r"
      when :cr
        "\r"
      when :crlf
        "\r\n"
      else
        raise ArgumentError, 'linefeed must be one of :lf, :lfcr, :cr, :crlf'
      end
    end

    # @deprecated
    def now
      (Time.now.to_f * 1000).to_i
    end

    # @deprecated
    def relative_path(from, to)
      Pathname.new(File.absolute_path(to)).relative_path_from(Pathname.new(File.absolute_path(from))).to_s
    end

    # @deprecated
    # The {LegacyImporter} for {Embedded#render}.
    class LegacyImporter
      def initialize(importer, file)
        super()
        @file = file
        @importer = importer
        @importer_results = {}
      end

      def canonicalize(url, **_kwargs)
        path = Url.file_url_to_path(url)
        canonical_url = Url.path_to_file_url(File.absolute_path(path, (@file.nil? ? 'stdin' : @file)))

        result = @importer.call canonical_url, @file

        raise result if result.is_a? StandardError

        if result&.key? :contents
          @importer_results[canonical_url] = {
            contents: result[:contents],
            syntax: :scss
          }
          canonical_url
        elsif result&.key? :file
          canonical_url = Url.path_to_file_url(File.absolute_path(result[:file]))
          @importer_results[canonical_url] = {
            contents: File.read(result[:file]),
            syntax: :scss
          }
          canonical_url
        end
      end

      def load(canonical_url)
        @importer_results[canonical_url]
      end
    end

    # @deprecated
    # The {Url} module.
    module Url
      # The {::URI::Parser} that is in consistent with RFC 2396 (URI Generic Syntax) and dart:core library.
      URI_PARSER = URI::Parser.new({ RESERVED: ';/?:@&=+$,' })

      FILE_SCHEME = 'file://'

      private_constant :URI_PARSER, :FILE_SCHEME

      module_function

      def path_to_file_url(path)
        if File.absolute_path? path
          URI_PARSER.escape "#{FILE_SCHEME}#{Gem.win_platform? ? '/' : ''}#{path}"
        else
          URI_PARSER.escape path
        end
      end

      def file_url_to_path(url)
        if url.start_with? FILE_SCHEME
          URI_PARSER.unescape url[(FILE_SCHEME.length + (Gem.win_platform? ? 1 : 0))..]
        else
          URI_PARSER.unescape url
        end
      end
    end

    private_constant :LegacyImporter
  end
end
