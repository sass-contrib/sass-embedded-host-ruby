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
    'documentation_uri' => "https://www.rubydoc.info/gems/#{spec.name}/#{spec.version}",
    'source_code_uri' => "#{spec.homepage}/tree/v#{spec.version}",
    'funding_uri' => 'https://github.com/sponsors/ntkme'
  }

  spec.extensions    = ['ext/sass/mkrf_conf.rb']
  spec.files         = Dir['lib/**/*.rb'] + [
    'ext/sass/mkrf_conf.rb',
    'ext/sass/package.json',
    'ext/sass/unzip.ps1',
    'ext/sass/unzip.vbs',
    'ext/sass/Rakefile',
    'LICENSE',
    'README.md'
  ]

  spec.required_ruby_version = '>= 2.6.0'

  spec.add_dependency 'google-protobuf', '~> 3.19.0'
  spec.add_dependency 'rake'

  spec.add_development_dependency 'rake', '~> 13.0.0'
  spec.add_development_dependency 'rspec', '~> 3.11.0'
  spec.add_development_dependency 'rubocop', '~> 1.25.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.13.0'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.9.0'
end
