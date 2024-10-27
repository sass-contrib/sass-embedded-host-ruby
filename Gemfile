# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development do
  # TODO: https://github.com/protocolbuffers/protobuf/issues/16853
  gem 'google-protobuf', force_ruby_platform: true if RUBY_PLATFORM == 'aarch64-linux-musl'

  gem 'rake', '>= 13'
  gem 'rspec', '~> 3.13.0'
  gem 'rubocop', '~> 1.67.0'
  gem 'rubocop-performance', '~> 1.22.0'
  gem 'rubocop-rake', '~> 0.6.0'
  gem 'rubocop-rspec', '~> 3.1.0'
end
