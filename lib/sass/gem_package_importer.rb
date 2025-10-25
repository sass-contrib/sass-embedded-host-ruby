# frozen_string_literal: true

module Sass
  # The built-in RubyGems package importer. This loads pkg: URLs from gems.
  class GemPackageImporter
    # @!visibility private
    def find_file_url(url, _canonicalize_context)
      return unless url.start_with?('pkg:')

      library, _, path = url[4..].partition(/[?#]/).first.partition('/')
      gem_dir = Gem::Dependency.new(library).to_spec.gem_dir

      "file://#{'/' unless gem_dir.start_with?('/')}#{gem_dir.gsub(/[?#]/, { '?' => '%3F', '#' => '%23' })}/#{path}"
    rescue Gem::MissingSpecError
      nil
    end
  end
end
