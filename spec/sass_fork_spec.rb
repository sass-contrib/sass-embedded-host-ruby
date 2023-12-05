# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sass, skip: (Process.respond_to?(:fork) ? false : 'Process.fork is not usable') do
  describe 'after fork' do
    it 'works in parent process' do
      pid = Process.fork do
        exit 0
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)

      expect(described_class.compile_string('a {b: c}').css)
        .to eq("a {\n  b: c;\n}")
    end

    it 'works in child process' do
      pid = Process.fork do
        expect(described_class.compile_string('a {b: c}').css)
          .to eq("a {\n  b: c;\n}")
        exit 0
      rescue StandardError
        exit 1
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)
    end

    it 'works in both parent and child process' do
      pid = Process.fork do
        expect(described_class.compile_string('a {b: c}').css)
          .to eq("a {\n  b: c;\n}")
        exit 0
      rescue StandardError
        exit 1
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)

      expect(described_class.compile_string('a {b: c}').css)
        .to eq("a {\n  b: c;\n}")
    end
  end

  describe 'running compiler after fork' do
    it 'remains running in parent process' do
      sass = Sass::Compiler.new
      expect(sass.closed?).to be(false)

      pid = Process.fork do
        exit 0
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)

      expect(sass.closed?).to be(false)
    ensure
      sass&.close
    end

    it 'is closed in child process' do
      sass = Sass::Compiler.new
      expect(sass.closed?).to be(false)

      pid = Process.fork do
        expect(sass.closed?).to be(true)
        exit 0
      rescue StandardError
        exit 1
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)
    ensure
      sass&.close
    end

    it 'works in parent process' do
      sass = Sass::Compiler.new

      pid = Process.fork do
        exit 0
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)

      expect(sass.compile_string('a {b: c}').css)
        .to eq("a {\n  b: c;\n}")
    ensure
      sass&.close
    end

    it 'works in child process' do
      sass = Sass::Compiler.new

      pid = Process.fork do
        expect(sass.compile_string('a {b: c}').css)
          .to eq("a {\n  b: c;\n}")
        exit 0
      rescue StandardError
        exit 1
      ensure
        sass.close
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)
    ensure
      sass&.close
    end

    it 'works in both parent and child process' do
      sass = Sass::Compiler.new

      pid = Process.fork do
        expect(sass.compile_string('a {b: c}').css)
          .to eq("a {\n  b: c;\n}")
        exit 0
      rescue StandardError
        exit 1
      ensure
        sass.close
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)

      expect(sass.compile_string('a {b: c}').css)
        .to eq("a {\n  b: c;\n}")
    ensure
      sass&.close
    end
  end

  describe 'closed compiler after fork' do
    it 'remains closed in parent process' do
      sass = Sass::Compiler.new
      sass.close
      expect(sass.closed?).to be(true)

      pid = Process.fork do
        exit 0
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)

      expect(sass.closed?).to be(true)
    ensure
      sass&.close
    end

    it 'remains closed in child process' do
      sass = Sass::Compiler.new
      sass.close
      expect(sass.closed?).to be(true)

      pid = Process.fork do
        expect(sass.closed?).to be(true)
        exit 0
      rescue StandardError
        exit 1
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)
    ensure
      sass&.close
    end

    it 'works in parent process' do
      sass = Sass::Compiler.new
      sass.close

      pid = Process.fork do
        exit 0
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)

      expect(sass.compile_string('a {b: c}').css)
        .to eq("a {\n  b: c;\n}")
    ensure
      sass&.close
    end

    it 'works in child process' do
      sass = Sass::Compiler.new
      sass.close

      pid = Process.fork do
        expect(sass.compile_string('a {b: c}').css)
          .to eq("a {\n  b: c;\n}")
        exit 0
      rescue StandardError
        exit 1
      ensure
        sass.close
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)
    ensure
      sass&.close
    end

    it 'works in both parent and child process' do
      sass = Sass::Compiler.new
      sass.close

      pid = Process.fork do
        expect(sass.compile_string('a {b: c}').css)
          .to eq("a {\n  b: c;\n}")
        exit 0
      rescue StandardError
        exit 1
      ensure
        sass.close
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)

      expect(sass.compile_string('a {b: c}').css)
        .to eq("a {\n  b: c;\n}")
    ensure
      sass&.close
    end
  end
end
