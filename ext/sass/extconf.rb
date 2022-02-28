#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'mkmf'
require 'open-uri'
require_relative '../../lib/sass/embedded/compiler'

module Sass
  class Embedded
    module Platform
      OS = case RbConfig::CONFIG['host_os'].downcase
           when /linux/
             'linux'
           when /darwin/
             'darwin'
           when /freebsd/
             'freebsd'
           when /netbsd/
             'netbsd'
           when /openbsd/
             'openbsd'
           when /dragonfly/
             'dragonflybsd'
           when /sunos|solaris/
             'solaris'
           when *Gem::WIN_PATTERNS
             'windows'
           else
             RbConfig::CONFIG['host_os'].downcase
           end

      OSVERSION = RbConfig::CONFIG['host_os'].gsub(/[^\d]/, '').to_i

      CPU = RbConfig::CONFIG['host_cpu']

      ARCH = case CPU.downcase
             when /amd64|x86_64|x64/
               'x86_64'
             when /i\d86|x86|i86pc/
               'i386'
             when /ppc64|powerpc64/
               'powerpc64'
             when /ppc|powerpc/
               'powerpc'
             when /sparcv9|sparc64/
               'sparcv9'
             when /arm64|aarch64/ # MacOS calls it "arm64", other operating systems "aarch64"
               'aarch64'
             when /^arm/
               if OS == 'darwin' # Ruby before 3.0 reports "arm" instead of "arm64" as host_cpu on darwin
                 'aarch64'
               else
                 'arm'
               end
             else
               RbConfig::CONFIG['host_cpu']
             end
    end

    private_constant :Platform

    # The dependency downloader. This downloads all the dependencies during gem
    # installation. The companion Makefile then unpacks all downloaded
    # dependencies. By default it downloads the release of each dependency
    # from GitHub releases.
    #
    # It is possible to specify an alternative source or version of each
    # dependency. Local sources can be used for offline installation.
    #
    # @example
    #   gem install sass-embedded -- \
    #     --with-protoc=file:///path/to/protoc-*.zip \
    #     --with-sass-embedded=file:///path/to/sass_embedded-*.(tar.gz|zip) \
    #     --with-sass-embedded-protocol=file:///path/to/embedded_sass.proto
    # @example
    #   bundle config build.sass-embedded \
    #     --with-protoc=file:///path/to/protoc-*.zip \
    #     --with-sass-embedded=file:///path/to/sass_embedded-*.(tar.gz|zip) \
    #     --with-sass-embedded-protocol=file:///path/to/embedded_sass.proto
    class Extconf
      def initialize
        fetch_with_config('protoc', false) { default_protoc }
        fetch_with_config('sass-embedded', false) { default_sass_embedded }
        fetch_with_config('sass-embedded-protocol', false) { default_sass_embedded_protocol }
      end

      private

      def fetch_with_config(config, default)
        val = with_config(config, default)
        case val
        when true
          if block_given?
            fetch yield
          else
            fetch default
          end
        when false
          nil
        else
          fetch val
        end
      end

      def fetch(uri_or_path)
        begin
          uri = URI.parse(uri_or_path)
          path = URI::DEFAULT_PARSER.unescape(uri.path)
          raise if uri.instance_of?(URI::Generic) && !File.file?(path)
        rescue StandardError
          raise unless File.file?(uri_or_path)

          uri = nil
          path = uri_or_path
        end

        dest = File.absolute_path(File.basename(path), __dir__)

        if uri.nil? || uri.is_a?(URI::File) || uri.instance_of?(URI::Generic)
          puts "cp -- #{path} #{dest}"
          FileUtils.copy_file(path, dest)
        elsif uri.respond_to?(:open)
          puts "curl -fsSLo #{dest} -- #{uri}"
          uri.open do |stream|
            File.binwrite(dest, stream.read)
          end
        else
          raise
        end
      rescue StandardError
        raise "Failed to fetch #{uri_or_path}"
      end

      def default_sass_embedded
        repo = 'sass/dart-sass-embedded'

        spec = JSON.parse(File.read(File.absolute_path('package.json', __dir__)))

        tag_name = spec['dependencies']['sass-embedded']

        os = case Platform::OS
             when 'darwin'
               'macos'
             when 'linux'
               'linux'
             when 'windows'
               'windows'
             else
               raise "Unsupported OS: #{Platform::OS}"
             end

        arch = case Platform::ARCH
               when 'x86_64'
                 'x64'
               when 'i386'
                 'ia32'
               when 'aarch64'
                 raise "Unsupported Arch: #{Platform::ARCH}" unless Platform::OS == 'darwin'

                 'x64'
               else
                 raise "Unsupported Arch: #{Platform::ARCH}"
               end

        ext = case os
              when 'windows'
                'zip'
              else
                'tar.gz'
              end

        "https://github.com/#{repo}/releases/download/#{tag_name}/sass_embedded-#{tag_name}-#{os}-#{arch}.#{ext}"
      end

      def default_protoc
        repo = 'protocolbuffers/protobuf'

        spec = Gem::Dependency.new('google-protobuf').to_spec

        tag_name = "v#{spec.version}"

        os = case Platform::OS
             when 'darwin'
               'osx'
             when 'linux'
               'linux'
             when 'windows'
               'win'
             else
               raise "Unsupported OS: #{Platform::OS}"
             end

        arch = case Platform::ARCH
               when 'aarch64'
                 if Platform::OS == 'darwin'
                   'x86_64'
                 else
                   'aarch_64'
                 end
               when 'sparcv9'
                 's390'
               when 'i386'
                 'x86_32'
               when 'x86_64'
                 'x86_64'
               when 'powerpc64'
                 'ppcle_64'
               else
                 raise "Unsupported Arch: #{Platform::ARCH}"
               end

        os_arch = case os
                  when 'win'
                    os + arch.split('_').last
                  else
                    "#{os}-#{arch}"
                  end

        ext = 'zip'

        "https://github.com/#{repo}/releases/download/#{tag_name}/protoc-#{tag_name.delete_prefix('v')}-#{os_arch}.#{ext}"
      end

      def default_sass_embedded_protocol
        repo = 'sass/embedded-protocol'

        stdout, stderr, status = Open3.capture3(Compiler::PATH, '--version')

        raise stderr unless status.success?

        tag_name = JSON.parse(stdout)['protocolVersion']

        "https://raw.githubusercontent.com/#{repo}/#{tag_name}/embedded_sass.proto"
      end
    end
  end
end

Sass::Embedded::Extconf.new
