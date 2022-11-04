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
    spec.required_rubygems_version = '>= 3.3.22' if ENV['gem_platform'].include?('-linux-')
  else
    spec.extensions = ['ext/sass/Rakefile']
    spec.files += Dir['ext/sass/*_pb.rb'] + [
      'ext/sass/expand-archive.ps1',
      'ext/sass/package.json',
      'ext/sass/Rakefile'
    ]
  end

  spec.required_ruby_version = '>= 2.6.0'

  spec.add_runtime_dependency 'google-protobuf', '~> 3.21'

  if ENV.key?('gem_platform')
    spec.add_development_dependency 'rake', '>= 10.0.0'
  else
    spec.add_runtime_dependency 'rake', '>= 10.0.0'
  end

  spec.add_development_dependency 'rspec', '~> 3.12.0'
  spec.add_development_dependency 'rubocop', '~> 1.38.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.15.0'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.15.0'
end
