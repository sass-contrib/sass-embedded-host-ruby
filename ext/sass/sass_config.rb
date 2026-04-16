# frozen_string_literal: true

require_relative 'platform'

# The {SassConfig} module.
module SassConfig
  module_function

  def package_json(path = '.')
    require 'json'

    JSON.parse(File.read(File.absolute_path('package.json', path)))
  end

  def dart_sass_version
    package_json(__dir__)['dependencies']['sass']
      # TODO: remove after https://github.com/sass/dart-sass/pull/2413
      .delete_prefix('file:sass-').delete_suffix('.tgz')
  end

  def dart_sass
    repo = 'https://github.com/sass/dart-sass'

    tag_name = dart_sass_version

    message = "dart-sass for #{Platform::ARCH} not available at #{repo}/releases/tag/#{tag_name}"

    env = ''

    os = case Platform::OS
         when 'darwin'
           'macos'
         when 'linux'
           'linux'
         when 'linux-android'
           'android'
         when 'linux-musl'
           env = '-musl'
           'linux'
         when 'windows'
           'windows'
         else
           raise NotImplementedError, message
         end

    cpu = case Platform::CPU
          when 'x86_64'
            'x64'
          when 'aarch64'
            'arm64'
          when 'arm'
            'arm'
          when 'riscv64'
            'riscv64'
          else
            raise NotImplementedError, message
          end

    ext = Platform::OS == 'windows' ? 'zip' : 'tar.gz'

    "#{repo}/releases/download/#{tag_name}/dart-sass-#{tag_name}-#{os}-#{cpu}#{env}.#{ext}"
  end

  def protoc
    repo = 'https://repo.maven.apache.org/maven2/com/google/protobuf/protoc'

    dependency = Gem::Dependency.new('google-protobuf')

    spec = dependency.to_spec

    version = spec.version

    message = "protoc for #{Platform::ARCH} not available at #{repo}/#{version}"

    os = case Platform::OS
         when 'darwin'
           'osx'
         when 'linux', 'linux-android', 'linux-musl', 'linux-none', 'linux-uclibc'
           'linux'
         when 'windows'
           'windows'
         else
           raise NotImplementedError, message
         end

    cpu = case Platform::CPU
          when 'i386'
            'x86_32'
          when 'x86_64'
            'x86_64'
          when 'aarch64'
            Platform::OS == 'windows' ? 'x86_64' : 'aarch_64'
          when 'ppc64le'
            'ppcle_64'
          when 's390x'
            's390_64'
          else
            raise NotImplementedError, message
          end

    uri = "#{repo}/#{version}/protoc-#{version}-#{os}-#{cpu}.exe"

    Utils.fetch_https("#{uri}.sha1")

    uri
  rescue Gem::RemoteFetcher::FetchError
    dependency_request = Gem::Resolver::DependencyRequest.new(dependency, nil)

    versions = Gem::Resolver::BestSet.new.find_all(dependency_request).filter_map do |s|
      s.version if s.platform == Gem::Platform::RUBY
    end

    versions.sort.reverse_each do |v|
      uri = "#{repo}/#{v}/protoc-#{v}-#{os}-#{cpu}.exe"

      Utils.fetch_https("#{uri}.sha1")

      return uri
    rescue Gem::RemoteFetcher::FetchError
      next
    end

    raise NotImplementedError, message
  end

  def embedded_sass_protocol
    require 'json'

    version = Utils.capture(RbConfig.ruby,
                            File.absolute_path('../../exe/sass', __dir__),
                            '--embedded',
                            '--version')

    tag_name = JSON.parse(version)['protocolVersion']

    "https://github.com/sass/sass/raw/embedded-protocol-#{tag_name}/spec/embedded_sass.proto"
  end

  def development?
    File.exist?('../../Gemfile')
  end

  def gem_version
    require_relative '../../lib/sass/embedded/version'

    development? ? dart_sass_version : Sass::Embedded::VERSION
  end

  def gem_platform
    platform = Gem::Platform.new("#{Platform::CPU}-#{Platform::HOST_OS}")
    case Platform::OS
    when 'darwin'
      case platform.cpu
      when 'aarch64'
        Gem::Platform.new(['arm64', platform.os])
      else
        platform
      end
    when 'linux'
      if platform.version&.start_with?('gnu')
        platform
      else
        Gem::Platform.new([platform.cpu, platform.os, "gnu#{platform.version}"])
      end
    when 'windows'
      case platform.cpu
      when 'x86_64'
        Gem::Platform.new('x64-mingw-ucrt')
      else
        Gem::Platform.new([platform.cpu, 'mingw', 'ucrt'])
      end
    else
      platform
    end
  end
end
