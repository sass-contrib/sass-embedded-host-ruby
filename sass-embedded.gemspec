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

  spec.extensions    = ['ext/sass/Rakefile']
  spec.files         = Dir['lib/**/*.rb'] + [
    'ext/sass/package.json',
    'ext/sass/unzip.vbs',
    'ext/sass/Rakefile',
    'LICENSE',
    'README.md'
  ]

  spec.required_ruby_version = '>= 2.6.0'

  spec.add_runtime_dependency 'google-protobuf', '~> 3.19'
  spec.add_runtime_dependency 'rake', '>= 10.0.0'

  spec.add_development_dependency 'rspec', '~> 3.11.0'
  spec.add_development_dependency 'rubocop', '~> 1.31.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.14.0'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.11.1'
end
