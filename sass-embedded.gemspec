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

  spec.files = Dir['lib/**/*.rb'] + ['LICENSE', 'README.md']

  if ENV.key?('gem_platform')
    spec.files += Dir['ext/sass/*.rb'] + Dir['ext/sass/sass_embedded/**/*']
    spec.platform = ENV['gem_platform']
    spec.required_rubygems_version = '>= 3.3.21' if ENV['gem_platform'].split('-', 2).last.start_with?('linux-')
  else
    spec.extensions = ['ext/sass/Rakefile']
    spec.files += [
      'ext/sass/package.json',
      'ext/sass/unzip.ps1',
      'ext/sass/unzip.vbs',
      'ext/sass/Rakefile'
    ]
  end

  spec.required_ruby_version = '>= 2.6.0'

  spec.add_runtime_dependency 'google-protobuf', '~> 3.19'

  if ENV.key?('gem_platform')
    spec.add_development_dependency 'rake', '>= 10.0.0'
  else
    spec.add_runtime_dependency 'rake', '>= 10.0.0'
  end

  spec.add_development_dependency 'rspec', '~> 3.11.0'
  spec.add_development_dependency 'rubocop', '~> 1.36.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.14.0'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.12.1'
end
