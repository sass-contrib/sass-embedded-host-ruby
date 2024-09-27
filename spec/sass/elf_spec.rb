# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sass::ELF', skip: (Sass.const_defined?(:ELF) ? false : 'Sass::ELF is not available') do
  let(:described_class) do
    Sass.const_get(:ELF)
  end

  describe 'ruby program interpreter' do
    it 'starts with ld-' do
      expect(File.basename(described_class::INTERPRETER)).to start_with('ld-')
    end
  end

  describe 'dart program interpreter' do
    subject(:interpreter) do
      Sass.const_get(:CLI)::INTERPRETER
    end

    it 'starts with ld-' do
      expect(File.basename(interpreter)).to start_with('ld-')
    end

    it 'is the same as ruby' do
      expect(File.basename(interpreter))
        .to eq(File.basename(described_class::INTERPRETER))
    end
  end
end
