# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sass::ForkTracker', skip: (Process.respond_to?(:fork) ? false : 'Process.fork is not usable') do
  let(:described_class) do
    Sass.const_get(:ForkTracker)
  end

  it 'tracks global compiler process' do
    Sass.compile_string('a { b: c }')

    expect(described_class.each.size).to eq(1)
  end

  it 'tracks new compiler process' do
    compiler = Sass::Compiler.new

    expect(described_class.each.size).to eq(2)

    compiler.close

    expect(described_class.each.size).to eq(1)
  end

  it 'tracks running compiler processes in parent process after fork' do
    expect(described_class.each.size).to eq(1)

    pid = Process.fork do
      exit 0
    end
    _, result = Process.wait2(pid)
    expect(result.exitstatus).to be(0)

    expect(described_class.each.size).to eq(1)
  end

  it 'closes running compiler processes in child process after fork' do
    compiler = Sass::Compiler.new

    pid = Process.fork do
      expect(described_class.each.size).to eq(0)
      exit 0
    rescue StandardError
      exit 1
    end
    _, result = Process.wait2(pid)
    expect(result.exitstatus).to be(0)

    compiler.close
  end

  describe 'global compiler' do
    it 'works in parent process after fork' do
      pid = Process.fork do
        exit 0
      end
      _, result = Process.wait2(pid)
      expect(result.exitstatus).to be(0)

      expect(Sass.compile_string('a {b: c}').css)
        .to eq("a {\n  b: c;\n}")
    end

    it 'works in child process after fork' do
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

    it 'works in both parent and child process after fork' do
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

  describe 'new compiler' do
    it 'works in parent process after fork' do
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

    it 'works in child process after fork' do
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

    it 'works in both parent and child process after fork' do
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

  describe 'closed compiler' do
    it 'remains closed in parent process after fork' do
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

    it 'remains closed in child process after fork' do
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
