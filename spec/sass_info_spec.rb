# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sass do
  describe '.info' do
    it 'begins with a unique identifier for the Sass implementation' do
      expect(described_class.info).to start_with("sass-embedded\t")
    end

    it 'followed by its package version' do
      version = described_class.info.split[1]
      expect { Gem::Version.new(version) }.not_to raise_error
    end
  end
end
