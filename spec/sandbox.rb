# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'uri'

module Sandbox
  def sandbox
    Dir.mktmpdir do |dir|
      yield SandboxDirectory.new(dir)
    end
  end

  class SandboxDirectory
    attr_accessor :root

    def initialize(root)
      @root = root
    end

    def path(*paths)
      File.join(@root, *paths)
    end

    def url(*paths)
      file_uri(path(*paths)).to_s
    end

    def relative_url(*paths)
      file_uri("#{Dir.pwd}/").route_to(url(*paths)).to_s
    end

    def write(paths)
      paths.each do |file, content|
        file = File.join(@root, file.to_s)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, content)
      end
    end

    def chdir(...)
      Dir.chdir(@root, ...)
    end

    private

    def file_uri(path)
      URI::File.build([nil, "#{path.start_with?('/') ? '' : '/'}#{URI::DEFAULT_PARSER.escape(path)}"])
    end
  end
end
