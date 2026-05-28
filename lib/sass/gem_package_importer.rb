# frozen_string_literal: true

module Sass
  # The built-in RubyGems package importer. This loads pkg: URLs from gems.
  #
  # @example
  #   require 'bundler/inline'
  #
  #   gemfile do
  #     source 'https://rubygems.org'
  #     gem 'bootstrap', require: false
  #     gem 'sass-embedded'
  #   end
  #
  #   puts Sass.compile_string('@use "pkg:bootstrap/assets/stylesheets/bootstrap";', importers: [Sass::GemPackageImporter.new]).css
  class GemPackageImporter
    # @!visibility private
    def find_file_url(url, _canonicalize_context)
      return unless url.start_with?('pkg:')

      library, _, path = url[4..].partition('/')
      gem_dir = Gem::Dependency.new(library).to_spec.gem_dir
      "#{Uri.path_to_file_uri(gem_dir)}/#{path}"
    rescue Gem::MissingSpecError
      nil
    end
  end
end
