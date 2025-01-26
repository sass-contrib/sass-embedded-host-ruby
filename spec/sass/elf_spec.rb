# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sass::ELF', skip: (Sass.const_defined?(:ELF) ? false : 'Sass::ELF is not available') do
  let(:described_class) do
    Sass.const_get(:ELF)
  end

  describe 'ruby', skip: (File.exist?('/proc/self/exe') ? false : 'procfs is not available') do
    it 'extracts program interpreter' do
      expect(File.basename(described_class::INTERPRETER)).to start_with('ld-')
    end

    it 'dumps elf headers' do
      input = StringIO.new(File.binread('/proc/self/exe'))
      output = StringIO.new.binmode

      described_class.new(input).dump(output)
      expect(output.string).to eq(input.string.slice(0, output.length))
    end
  end

  describe 'dart' do
    subject(:interpreter) do
      Sass.const_get(:CLI)::INTERPRETER
    end

    it 'extracts program interpreter' do
      expect(File.basename(interpreter)).to start_with('ld-')
    end

    it 'dumps elf headers' do
      input = StringIO.new(File.binread(Sass.const_get(:CLI)::COMMAND[0]))
      output = StringIO.new.binmode

      described_class.new(input).dump(output)
      expect(output.string).to eq(input.string.slice(0, output.length))
    end
  end
end
