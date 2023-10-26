# frozen_string_literal: true

require_relative 'lib/sass/embedded/version'

Gem::Specification.new do |spec| # rubocop:disable Gemspec/RequireMFA
  spec.name          = 'sass-embedded'
  spec.version       = Sass::Embedded::VERSION
  spec.authors       = ['なつき']
  spec.email         = ['i@ntk.me']
  spec.summary       = 'Use dart-sass with Ruby!'
  spec.description   = 'A Ruby library that will communicate with Embedded Dart Sass using the Embedded Sass protocol.'
  spec.homepage      = 'https://github.com/ntkme/sass-embedded-host-ruby'
  spec.license       = 'MIT'
  spec.metadata      = {
    'documentation_uri' => "https://rubydoc.info/gems/#{spec.name}/#{spec.version}",
    'source_code_uri' => "#{spec.homepage}/tree/v#{spec.version}",
    'funding_uri' => 'https://github.com/sponsors/ntkme'
  }

  spec.bindir      = 'exe'
  spec.executables = ['sass']
  spec.files       = Dir['exe/**/*', 'ext/**/*_pb.rb', 'lib/**/*.rb'] + ['LICENSE', 'README.md']

  if ENV.key?('gem_platform')
    spec.files += Dir['ext/sass/dart-sass/**/*'] + ['ext/sass/cli.rb']
    spec.platform = ENV['gem_platform']
    spec.required_rubygems_version = '>= 3.3.22' if ENV['gem_platform'].include?('-linux-')
  else
    spec.extensions = ['ext/sass/Rakefile']
    spec.files += [
      'ext/sass/Rakefile',
      'ext/sass/expand-archive.ps1',
      'ext/sass/package.json',
      'ext/sass/win32_api.rb'
    ]
  end

  spec.required_ruby_version = '>= 3.0.0'

  spec.add_runtime_dependency 'google-protobuf', '~> 3.24'
  spec.add_runtime_dependency 'rake', '>= 13.0.0' unless ENV.key?('gem_platform')
end
