# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sass::ForkTracker', skip: (Process.respond_to?(:fork) ? false : 'Process.fork is not usable') do
  describe 'global compiler after fork' do
    it 'works in parent process' do
      pid = Process.fork do
        exit 0
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)

      expect(Sass.compile_string('a {b: c}').css)
        .to eq("a {\n  b: c;\n}")
    end

    it 'works in child process' do
      pid = Process.fork do
        expect(Sass.compile_string('a {b: c}').css)
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
        expect(Sass.compile_string('a {b: c}').css)
          .to eq("a {\n  b: c;\n}")
        exit 0
      rescue StandardError
        exit 1
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)

      expect(Sass.compile_string('a {b: c}').css)
        .to eq("a {\n  b: c;\n}")
    end
  end

  describe 'opened compiler after fork' do
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
  end
end
