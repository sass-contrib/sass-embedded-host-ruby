# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development do
  # TODO: https://github.com/protocolbuffers/protobuf/issues/16853
  gem 'google-protobuf', force_ruby_platform: RUBY_PLATFORM.include?('linux-musl')

  gem 'rake', '>= 13'
  gem 'rspec', '~> 3.13.0'
  gem 'rubocop', '~> 1.71.0'
  gem 'rubocop-performance', '~> 1.23.0'
  gem 'rubocop-rake', '~> 0.6.0'
  gem 'rubocop-rspec', '~> 3.4.0'
end
