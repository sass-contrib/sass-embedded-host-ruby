# frozen_string_literal: true

require_relative 'lib/sass/embedded/version'

Gem::Specification.new do |spec|
  spec.name          = 'sass-embedded'
  spec.version       = Sass::Embedded::VERSION
  spec.authors       = ['なつき']
  spec.email         = ['i@ntk.me']
  spec.summary       = 'Use dart-sass with Ruby!'
  spec.description   = 'A Ruby library that will communicate with Embedded Dart Sass using the Embedded Sass protocol.'
  spec.homepage      = 'https://github.com/sass-contrib/sass-embedded-host-ruby'
  spec.license       = 'MIT'
  spec.metadata      = {
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'documentation_uri' => "https://rubydoc.info/gems/#{spec.name}/#{spec.version}",
    'source_code_uri' => "#{spec.homepage}/tree/v#{spec.version}",
    'funding_uri' => 'https://github.com/sponsors/ntkme',
    'rubygems_mfa_required' => 'true'
  }

  spec.bindir      = 'exe'
  spec.executables = ['sass']
  spec.files       = Dir['exe/**/*', 'ext/**/*_pb.rb', 'lib/**/*.rb'] + ['LICENSE', 'README.md']
  spec.platform    = ENV.fetch('gem_platform', 'ruby')

  if spec.platform == Gem::Platform::RUBY
    spec.extensions = ['ext/sass/Rakefile']
    spec.files += [
      'ext/sass/Rakefile',
      'ext/sass/expand-archive.ps1',
      'ext/sass/package.json'
    ]
    spec.add_runtime_dependency 'rake', '>= 13.0.0'
  else
    spec.files += Dir['ext/sass/dart-sass/**/*'] + ['ext/sass/cli.rb']
  end

  spec.required_ruby_version = if spec.platform == Gem::Platform::RUBY || spec.platform.os != 'linux'
                                 '>= 3.1.0'
                               else
                                 '>= 3.2.0'
                               end

  spec.add_runtime_dependency 'google-protobuf', '>= 3.25', '< 5.0'
end
