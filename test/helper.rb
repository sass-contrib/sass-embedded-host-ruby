# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/around/unit'

require_relative '../lib/sass/embedded'

module TempFileTest
  def around
    pwd = Dir.pwd
    tmpdir = Dir.mktmpdir
    Dir.chdir tmpdir
    yield
    Dir.chdir pwd
    FileUtils.rm_rf(tmpdir)
  end

  def temp_file(filename, contents)
    File.open(filename, 'w') do |file|
      file.write(contents)
    end
  end

  def temp_dir(directory)
    Dir.mkdir(directory)
  end
end
