# frozen_string_literal: true

require_relative 'lib/sass/version'
require_relative 'ext/dependencies'

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
    'source_code_uri' => "https://github.com/ntkme/sass-embedded-host-ruby/tree/v#{Sass::VERSION}"
  }

  spec.extensions    = ['ext/extconf.rb']
  spec.files         = Dir['lib/**/*.rb'] + [
    'ext/dependencies.rb',
    'ext/extconf.rb',
    'ext/Makefile',
    'LICENSE',
    'README.md'
  ]

  spec.required_ruby_version = '>= 2.6.0'

  spec.add_dependency 'google-protobuf', Sass::Dependencies::REQUIREMENTS['protocolbuffers/protobuf']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest', '~> 5.14.4'
  spec.add_development_dependency 'minitest-around'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rake-compiler'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-minitest'
  spec.add_development_dependency 'rubocop-rake'
end
