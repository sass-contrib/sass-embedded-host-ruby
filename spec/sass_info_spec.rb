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
      version = described_class.info.split[1]
      expect(version).to eq(described_class::Embedded::VERSION)
    end
  end
end
