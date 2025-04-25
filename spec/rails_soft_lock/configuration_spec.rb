# frozen_string_literal: true

RSpec.describe RailsSoftLock::Configuration do
  let(:config) { described_class.new }

  describe "#adapter=" do
    it "sets a valid adapter" do
      config.adapter = :nats
      expect(config.adapter).to eq(:nats)
    end

    it "raises an error for invalid adapter" do
      expect { config.adapter = :invalid }.to raise_error(ArgumentError, /Adapter must be one of/)
    end
  end

  describe ".configure" do
    it "yields the configuration object" do
      RailsSoftLock.configure do |config|
        config.adapter = :memcached
      end
      expect(RailsSoftLock.configuration.adapter).to eq(:memcached)
    end
  end
end
