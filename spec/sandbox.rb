# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'uri'

module Sandbox
  def sandbox
    Dir.mktmpdir do |dir|
      yield SandboxDirectory.new dir
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
      URI::File.build([nil, "#{@root.start_with?('/') ? '' : '/'}#{URI::DEFAULT_PARSER.escape(path(*paths))}"]).to_s
    end

    def write(paths)
      paths.each do |file, content|
        file = File.join(@root, file.to_s)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, content)
      end
    end

    def chdir(&block)
      Dir.chdir @root, &block
    end
  end
end
