# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sass do
  describe '.info' do
    let(:identifier) do
      'sass-embedded'
    end

    it 'begins with a unique identifier for the Sass implementation' do
      expect(described_class.info).to start_with(identifier)
    end

    it 'followed by U+0009 TAB' do
      expect(described_class.info[identifier.length]).to eq("\t")
    end

    it 'followed by its package version' do
      version = described_class.info.slice(identifier.length + 1).split[0]
      expect { Gem::Version.new(version) }.not_to raise_error
    end
  end
end
