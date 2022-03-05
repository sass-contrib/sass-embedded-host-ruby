#!/usr/bin/env ruby
# frozen_string_literal: true

exit if __FILE__ == $PROGRAM_NAME

require 'json'
require 'open-uri'
require 'open3'

# @private
module FileUtils
  def unzip(source, dest = '.')
    if Gem.win_platform?
      sh 'powershell -c "'\
         'if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {'\
         " Get-Item #{source} | Expand-Archive -DestinationPath #{dest} -Force "\
         '} else {'\
         " cscript.exe unzip.vbs #{source} #{dest} "\
         '}"'
    else
      sh "unzip -od #{dest} #{source}"
    end
  end

  def fetch(uri_or_path, dest = nil)
    begin
      uri = URI.parse(uri_or_path)
      path = URI::DEFAULT_PARSER.unescape(uri.path)
      if uri.instance_of?(URI::File) || uri.instance_of?(URI::Generic)
        path = path.delete_prefix('/') if Platform::OS == 'windows' && !File.file?(path)
        raise unless File.file?(path)
      end
    rescue StandardError
      raise unless File.file?(uri_or_path)

      uri = nil
      path = uri_or_path
    end

    dest = File.basename(path) if dest.nil?

    if uri.nil? || uri.instance_of?(URI::File) || uri.instance_of?(URI::Generic)
      puts "cp -- #{path} #{dest}"
      cp path, dest
    elsif uri.respond_to?(:open)
      puts "curl -fsSLo #{dest} -- #{uri}"
      uri.open do |stream|
        File.binwrite(dest, stream.read)
      end
    else
      raise
    end

    dest
  rescue StandardError
    raise "Failed to fetch #{uri_or_path}"
  end
end

# The {MkrfConf} module.
#
# This resolves all the default dependencies during gem installation.
# The companion Rakefile will download and unpack all dependencies.
# By default dependencies are downloaded from GitHub releases.
#
# It is possible to specify an alternative source location for each dependency.
# Local sources can be used for offline installation.
#
# @example
#   gem install sass-embedded -- \
#     PROTOC=file:///path/to/protoc-*.zip \
#     SASS_EMBEDDED=file:///path/to/sass_embedded-*.(tar.gz|zip) \
#     SASS_EMBEDDED_PROTOCOL=file:///path/to/embedded_sass.proto
# @example
#   bundle config build.sass-embedded \
#     PROTOC=file:///path/to/protoc-*.zip \
#     SASS_EMBEDDED=file:///path/to/sass_embedded-*.(tar.gz|zip) \
#     SASS_EMBEDDED_PROTOCOL=file:///path/to/embedded_sass.proto
module MkrfConf
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

  class << self
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
             raise release_asset_not_available_error(repo, tag_name)
           end

      arch = case Platform::ARCH
             when 'x86_64'
               'x64'
             when 'i386'
               'ia32'
             when 'aarch64'
               Platform::OS == 'darwin' ? 'x64' : 'arm64'
             else
               raise release_asset_not_available_error(repo, tag_name)
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
             raise release_asset_not_available_error(repo, tag_name)
           end

      arch = case Platform::ARCH
             when 'aarch64'
               Platform::OS == 'darwin' ? 'x86_64' : 'aarch_64'
             when 'sparcv9'
               's390'
             when 'i386'
               'x86_32'
             when 'x86_64'
               'x86_64'
             when 'powerpc64'
               'ppcle_64'
             else
               raise release_asset_not_available_error(repo, tag_name)
             end

      os_arch = case os
                when 'win'
                  os + arch.split('_').last
                else
                  "#{os}-#{arch}"
                end

      ext = 'zip'

      "https://github.com/#{repo}/releases/download/#{tag_name}/protoc-#{spec.version}-#{os_arch}.#{ext}"
    end

    def default_sass_embedded_protocol
      stdout, stderr, status = Open3.capture3(
        File.absolute_path("sass_embedded/dart-sass-embedded#{Gem.win_platform? ? '.bat' : ''}", __dir__), '--version'
      )
      raise stderr unless status.success?

      tag_name = JSON.parse(stdout)['protocolVersion']
      "https://github.com/sass/embedded-protocol/raw/#{tag_name}/embedded_sass.proto"
    end

    private

    def release_asset_not_available_error(repo, tag_name)
      NotImplementedError.new(
        "Release asset for #{Platform::OS} #{Platform::ARCH} "\
        "not available at https://github.com/#{repo}/releases/tag/#{tag_name}"
      )
    end
  end
end
