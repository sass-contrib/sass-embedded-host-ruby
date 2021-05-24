#!/usr/bin/env ruby
# frozen_string_literal: true

require 'mkmf'
require 'json'
require 'open-uri'
require_relative '../../lib/sass/platform'

module Sass
  class Extconf

    def initialize
      system('make', '-C', __dir__, 'distclean')
      download_sass_embedded
      download_protoc
      download_embedded_sass_proto
      system('make', '-C', __dir__, 'install')

      File.open(File.absolute_path("sass_embedded.#{RbConfig::CONFIG['DLEXT']}", __dir__), 'w') {}

      $makefile_created = true
    end

    private

    def api(url)
      headers = {}
      headers['Authorization'] = "token #{ENV['GITHUB_TOKEN']}" if ENV['GITHUB_TOKEN']
      URI.parse(url).open(headers) do |file|
        JSON.parse file.read
      end
    end

    def download(url)
      URI.parse(url).open do |source|
        File.open(File.absolute_path(File.basename(url), __dir__), 'wb') do |destination|
          destination.write source.read
        end
      end
    rescue StandardError
      raise "Failed to download: #{url}"
    end

    def download_sass_embedded
      repo = 'sass/dart-sass-embedded'

      release = api("https://api.github.com/repos/#{repo}/releases")[0]['tag_name']

      os = case Sass::Platform::OS
           when 'darwin'
             'macos'
           when 'linux'
             'linux'
           when 'windows'
             'windows'
           else
             raise "Unsupported OS: #{Sass::Platform::OS}"
           end

      arch = case Sass::Platform::ARCH
             when 'x86_64'
               'x64'
             when 'i386'
               'ia32'
             else
               raise "Unsupported Arch: #{Sass::Platform::ARCH}"
             end

      ext = case os
            when 'windows'
              'zip'
            else
              'tar.gz'
            end

      url = "https://github.com/#{repo}/releases/download/#{release}/sass_embedded-#{release}-#{os}-#{arch}.#{ext}"
      download url
    end

    def download_protoc
      repo = 'protocolbuffers/protobuf'

      tag = URI.parse("https://github.com/#{repo}/releases/latest").open do |file|
        File.basename file.base_uri.to_s
      end

      release = tag[1..-1]

      os = case Sass::Platform::OS
           when 'darwin'
             'osx'
           when 'linux'
             'linux'
           when 'windows'
             'win'
           else
             raise "Unsupported OS: #{Sass::Platform::OS}"
           end

      arch = case Sass::Platform::ARCH
             when 'aarch64'
               'aarch_64'
             when 'sparcv9'
               's390'
             when 'i386'
               'x86_32'
             when 'x86_64'
               'x86_64'
             when 'powerpc64'
               'ppcle_64'
             else
               raise "Unsupported Arch: #{Sass::Platform::ARCH}"
             end

      os_arch = case os
                when 'win'
                  os + arch.split('_').last
                else
                  "#{os}-#{arch}"
                end

      ext = 'zip'

      url = "https://github.com/#{repo}/releases/download/#{tag}/protoc-#{release}-#{os_arch}.#{ext}"
      download url
    end

    def download_embedded_sass_proto
      url = 'https://raw.githubusercontent.com/sass/embedded-protocol/HEAD/embedded_sass.proto'
      download url
    end

  end
end

Sass::Extconf.new
