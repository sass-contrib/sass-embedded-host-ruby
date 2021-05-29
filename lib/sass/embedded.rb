# frozen_string_literal: true

require 'base64'
require 'json'

module Sass
  # The {Embedded} host for using dart-sass-embedded. Each instance creates
  # its own {Transport}.
  #
  # @example
  #   embedded = Sass::Embedded.new
  #   result = embedded.render(data: 'h1 { font-size: 40px; }')
  #   result = embedded.render(file: 'style.css')
  #   embedded.close
  class Embedded
    def initialize
      @transport = Transport.new
      @id_semaphore = Mutex.new
      @id = 0
    end

    # The {Embedded#info} method.
    #
    # @raise [ProtocolError]
    def info
      @info ||= Version.new(@transport, next_id).message
    end

    # The {Embedded#render} method.
    #
    # See {file:README.md#options} for supported options.
    #
    # @return [RenderResult]
    # @raise [ProtocolError]
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
      raise NotImplementedError, 'source_map_contents is not implemented' unless source_map_contents == false

      start = Util.now

      indent_type = parse_indent_type(indent_type)
      indent_width = parse_indent_width(indent_width)
      linefeed = parse_linefeed(linefeed)

      message = Render.new(@transport, next_id,
                           data: data,
                           file: file,
                           indented_syntax: indented_syntax,
                           include_paths: include_paths,
                           output_style: output_style,
                           source_map: source_map,
                           out_file: out_file,
                           functions: functions,
                           importer: importer).message

      if message.failure
        raise RenderError.new(
          message.failure.message,
          message.failure.formatted,
          if message.failure.span.nil?
            nil
          elsif message.failure.span.url == ''
            'stdin'
          else
            Util.path(message.failure.span.url)
          end,
          message.failure.span ? message.failure.span.start.line + 1 : nil,
          message.failure.span ? message.failure.span.start.column + 1 : nil,
          1
        )
      end

      map, source_map = post_process_map(map: message.success.source_map,
                                         file: file,
                                         out_file: out_file,
                                         source_map: source_map,
                                         source_map_root: source_map_root)

      css = post_process_css(css: message.success.css,
                             indent_type: indent_type,
                             indent_width: indent_width,
                             linefeed: linefeed,
                             map: map,
                             out_file: out_file,
                             omit_source_map_url: omit_source_map_url,
                             source_map: source_map,
                             source_map_embed: source_map_embed)

      finish = Util.now

      stats = RenderResult::Stats.new(file.nil? ? 'data' : file, start, finish, finish - start)

      RenderResult.new(css, map, stats)
    end

    def close
      @transport.close
    end

    def closed?
      @transport.closed?
    end

    private

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
        map_data['file'] = Util.relative(source_map_dir, out_file)
      elsif file
        ext = File.extname(file)
        map_data['file'] = "#{file[0..(ext.empty? ? -1 : -ext.length - 1)]}.css"
      else
        map_data['file'] = 'stdin.css'
      end

      map_data['sources'].map! do |source|
        if source.start_with? Util::FILE_PROTOCOL
          Util.relative(source_map_dir, Util.path(source))
        else
          source
        end
      end

      [-JSON.generate(map_data), source_map_path]
    end

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
                Util.relative(File.dirname(out_file), source_map)
              else
                source_map
              end
        css += "#{linefeed}/*# sourceMappingURL=#{url} */"
      end

      -css
    end

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

    def parse_indent_width(indent_width)
      raise ArgumentError, 'indent_width must be an integer' unless indent_width.is_a? Integer
      raise RangeError, 'indent_width must be in between 0 and 10 (inclusive)' unless indent_width.between? 0, 10

      indent_width
    end

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

    def next_id
      @id_semaphore.synchronize do
        @id += 1
        @id = 0 if @id == Transport::PROTOCOL_ERROR_ID
        @id
      end
    end
  end
end
