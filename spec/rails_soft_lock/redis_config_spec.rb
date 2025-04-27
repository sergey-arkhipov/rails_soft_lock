# frozen_string_literal: true

# spec/rails_soft_lock/redis_config_spec.rb
require "spec_helper"
require "rails_soft_lock/redis_config"

RSpec.describe RailsSoftLock::RedisConfig do
  describe ".default_adapter_options" do
    it "returns default redis configuration hash" do
      expect(described_class.default_adapter_options).to eq(
        redis: {
          host: "localhost",
          port: 6379,
          db: 0,
          timeout: 5
        }
      )
    end
  end

  describe ".config_with_defaults" do
    it "returns default configuration when no Rails" do
      hide_const("Rails")
      expect(described_class.config_with_defaults).to eq(
        host: "localhost",
        port: 6379,
        db: 0,
        timeout: 5
      )
    end

    context "with Rails simulation" do
      # We use simple doubles since we're testing behavior, not Rails internals
      let(:rails_app) { double("Rails.application") } # rubocop:disable RSpec/VerifiedDoubles

      before do
        stub_const("Rails", Class.new)
        allow(Rails).to receive(:application).and_return(rails_app)
      end

      it "returns defaults when config_for unavailable" do
        allow(rails_app).to receive(:respond_to?).with(:config_for).and_return(false)
        expect(described_class.config_with_defaults).to include(port: 6379)
      end

      context "when redis config is available" do # rubocop:disable RSpec/NestedGroups
        before do
          allow(rails_app).to receive(:respond_to?).with(:config_for).and_return(true)
          allow(rails_app).to receive(:config_for)
            .with(:redis)
            .and_return("host" => "redis.test", "port" => 6380)
        end

        it "uses custom host" do
          expect(described_class.config_with_defaults[:host]).to eq("redis.test")
        end

        it "uses custom port" do
          expect(described_class.config_with_defaults[:port]).to eq(6380)
        end

        it "preserves default db" do
          expect(described_class.config_with_defaults[:db]).to eq(0)
        end
      end
    end
  end

  describe ".rails_available?" do
    it "returns false without Rails" do
      hide_const("Rails")
      expect(described_class.rails_available?).to be false
    end

    it "returns false with incomplete Rails" do
      # We don't need verified doubles for testing framework absence
      stub_const("Rails", Class.new)
      expect(described_class.rails_available?).to be false
    end
  end
end
