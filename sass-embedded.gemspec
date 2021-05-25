# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sass/version'

Gem::Specification.new do |spec|
  spec.name          = 'sass-embedded'
  spec.version       = Sass::VERSION
  spec.authors       = ['なつき']
  spec.email         = ['i@ntk.me']
  spec.summary       = 'Use dart-sass with Ruby!'
  spec.description   = 'Use dart-sass with Ruby!'
  spec.homepage      = 'https://github.com/ntkme/embedded-host-ruby'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.extensions    = ['ext/extconf.rb']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.required_ruby_version = '>= 2.6'

  spec.require_paths = ['lib']

  spec.platform      = Gem::Platform::RUBY

  spec.add_dependency 'google-protobuf', '~> 3.17.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest', '~> 5.14.4'
  spec.add_development_dependency 'minitest-around'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rake-compiler'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-minitest'
  spec.add_development_dependency 'rubocop-rake'
end
