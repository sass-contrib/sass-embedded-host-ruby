#!/usr/bin/env ruby
# frozen_string_literal: true

require 'mkmf'
require 'json'
require 'open-uri'
require 'fileutils'
require_relative './dependencies'
require_relative '../../lib/sass/platform'

module Sass
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
  class Extconf
    def initialize
      get_with_config('protoc', true) { default_protoc }
      get_with_config('sass-embedded', true) { default_sass_embedded }
      get_with_config('sass-embedded-protocol', true) { default_sass_embedded_protocol }
    end

    private

    def get_with_config(config, default)
      val = with_config(config, default)
      case val
      when true
        if block_given?
          get yield
        else
          get default
        end
      when false
        nil
      else
        get val
      end
    end

    def get(uri_s)
      uri = URI.parse(uri_s)
      path = File.absolute_path(File.basename(uri.path), __dir__)
      if uri.is_a?(URI::File) || uri.instance_of?(URI::Generic)
        FileUtils.copy_file uri.path, path
      elsif uri.respond_to? :open
        puts "curl -fsSLo #{path} -- #{uri}"
        uri.open do |source|
          File.open(path, 'wb') do |destination|
            destination.write source.read
          end
        end
      else
        raise
      end
    rescue StandardError
      warn "Failed to get: #{uri_s}"
      raise
    end

    def resolve_tag_name(repo, *requirements, gh_release: true)
      requirements = Gem::Requirement.create(*requirements)

      if requirements == Gem::Requirement.default && gh_release
        URI.parse("https://github.com/#{repo}/releases/latest").open do |file|
          File.basename file.base_uri.to_s
        end
      else
        begin
          headers = {}
          headers['Authorization'] = "token #{ENV['GITHUB_TOKEN']}" if ENV['GITHUB_TOKEN']
          if gh_release
            URI.parse("https://api.github.com/repos/#{repo}/releases?per_page=100").open(headers) do |file|
              JSON.parse(file.read).map { |release| release['tag_name'] }
            end
          else
            URI.parse("https://api.github.com/repos/#{repo}/tags?per_page=100").open(headers) do |file|
              JSON.parse(file.read).map { |tag| tag['name'] }
            end
          end
        rescue OpenURI::HTTPError
          requirements.requirements
                      .map { |requirement| requirement.last.to_s.gsub('.pre.', '-') }
        end
          .find { |version| Gem::Version.correct?(version) && requirements.satisfied_by?(Gem::Version.new(version)) }
          &.to_s
      end
    end

    def default_sass_embedded
      repo = 'sass/dart-sass-embedded'

      tag_name = resolve_tag_name(repo, Sass::Dependencies::REQUIREMENTS[repo])

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

      spec = Gem::Dependency.new('google-protobuf', Sass::Dependencies::REQUIREMENTS[repo]).to_spec

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

      "https://github.com/#{repo}/releases/download/#{tag_name}/protoc-#{tag_name[1..]}-#{os_arch}.#{ext}"
    end

    def default_sass_embedded_protocol
      repo = 'sass/embedded-protocol'

      tag_name = resolve_tag_name(repo, Sass::Dependencies::REQUIREMENTS[repo], gh_release: false)

      "https://raw.githubusercontent.com/#{repo}/#{tag_name}/embedded_sass.proto"
    end
  end
end

Sass::Extconf.new
