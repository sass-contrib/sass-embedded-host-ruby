# frozen_string_literal: true

require_relative 'lib/sass/version'
require_relative 'ext/sass/dependencies'

Gem::Specification.new do |spec|
  spec.name          = 'sass-embedded'
  spec.version       = Sass::VERSION
  spec.authors       = ['なつき']
  spec.email         = ['i@ntk.me']
  spec.summary       = 'Use dart-sass with Ruby!'
  spec.description   = 'A Ruby library that will communicate with Embedded Dart Sass using the Embedded Sass protocol.'
  spec.homepage      = 'https://github.com/ntkme/sass-embedded-host-ruby'
  spec.license       = 'MIT'
  spec.metadata      = {
    'documentation_uri' => "https://www.rubydoc.info/gems/#{spec.name}/#{spec.version}",
    'source_code_uri' => "#{spec.homepage}/tree/v#{spec.version}",
    'funding_uri' => 'https://github.com/sponsors/ntkme'
  }

  spec.extensions    = ['ext/sass/extconf.rb']
  spec.files         = Dir['lib/**/*.rb'] + [
    'ext/sass/dependencies.rb',
    'ext/sass/extconf.rb',
    'ext/sass/unzip.vbs',
    'ext/sass/Makefile',
    'LICENSE',
    'README.md'
  ]

  spec.required_ruby_version = '>= 2.6.0'

  spec.add_dependency 'google-protobuf', Sass::Dependencies::REQUIREMENTS['protocolbuffers/protobuf']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest', '~> 5.14.4'
  spec.add_development_dependency 'minitest-around'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-minitest'
  spec.add_development_dependency 'rubocop-rake'
end
