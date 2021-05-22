#!/usr/bin/env ruby

require "mkmf"
require "json"
require "open-uri"
require_relative "../../lib/sass/platform"

def api url
  headers = {}
  headers["Authorization"] = "token #{ENV["GITHUB_TOKEN"]}" if ENV["GITHUB_TOKEN"]
  URI.open(url, headers) do |file|
    JSON.parse file.read
  end
end

def download url
  URI.open(url) do |source|
    File.open(File.absolute_path(File.basename(url), __dir__), "wb") do |destination|
      destination.write source.read
    end
  end
end

def download_sass_embedded
  repo = "sass/dart-sass-embedded"

  release = api("https://api.github.com/repos/#{repo}/releases")[0]['tag_name']

  os = case Sass::Platform::OS
       when "darwin"
         "macos"
       when "linux"
         "linux"
       when "windows"
         "windows"
       else
         raise "Unsupported OS: #{Sass::Platform::OS}"
       end

  arch = case Sass::Platform::ARCH
         when "x86_64"
           "x64"
         when "i386"
           "ia32"
         else
           raise "Unsupported Arch: #{Sass::Platform::ARCH}"
         end


  ext = case os
        when "windows"
          "zip"
        else
          "tar.gz"
        end

  url = "https://github.com/#{repo}/releases/download/#{release}/sass_embedded-#{release}-#{os}-#{arch}.#{ext}"

  begin
    download url
  rescue
    raise "Failed to download: #{url}"
  end
end

system("make", "-C", __dir__, "distclean")
download_sass_embedded
system("make", "-C", __dir__, "install")

File.open(File.absolute_path("sass_embedded.#{RbConfig::CONFIG['DLEXT']}", __dir__), "w") {}

$makefile_created = true
