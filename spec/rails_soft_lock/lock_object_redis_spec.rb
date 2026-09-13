# spec/rails_soft_lock/lock_object_redis_spec.rb

# frozen_string_literal: true

require "spec_helper"
require "rails_soft_lock/lock_object"

RSpec.describe RailsSoftLock::LockObject, adapter: :redis do
  let(:object_name) { "test_locks" }
  let(:object_key) { "key1" }
  let(:object_value) { "locker1" }
  let(:lock_object) do
    described_class.new(object_name: object_name, object_key: object_key, object_value: object_value)
  end

  before do
    # Configure redis for test
    RailsSoftLock.configure do |config|
      config.adapter = :redis
      config.adapter_options = { redis: { url: ENV["REDIS_URL"] || "redis://localhost:6379/0", timeout: 5 } }
    end
    # Clear Redis before each test
    redis = Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379/0")
    redis.del(object_name)
    # Reset redis_client
    lock_object.instance_variable_set(:@redis_client, nil)
  end

  describe "#initialize" do
    it "sets object_name" do
      expect(lock_object.object_name).to eq(object_name)
    end

    it "setsobject_key" do
      expect(lock_object.object_key).to eq(object_key)
    end

    it "sets object_value" do
      expect(lock_object.object_value).to eq(object_value)
    end

    it "converts object_value to string" do
      lock = described_class.new(object_name: object_name, object_key: object_key, object_value: 123)
      expect(lock.object_value).to eq("123")
    end
  end

  describe "#redis_client" do
    it "creates a ConnectionPool::Wrapper with default options when no redis config is provided" do # rubocop:disable RSpec/ExampleLength
      # Clear Redis configuration
      RailsSoftLock.configure do |config|
        config.adapter = :redis
        config.adapter_options = {}
      end

      allow(ConnectionPool::Wrapper).to receive(:new) do |&block|
        allow(Redis).to receive(:new).with(url: "redis://localhost:6379/0",
                                           timeout: 5).and_return(instance_double(Redis))
        block.call
      end.and_return(instance_double(ConnectionPool::Wrapper))

      lock_object.send(:redis_client)
      expect(ConnectionPool::Wrapper).to have_received(:new)
    end

    it "creates a ConnectionPool::Wrapper with custom redis config" do # rubocop:disable RSpec/ExampleLength
      RailsSoftLock.configure do |config|
        config.adapter = :redis
        config.adapter_options = {
          redis: { url: "redis://custom:6379/0", timeout: 10 }
        }
      end

      allow(ConnectionPool::Wrapper).to receive(:new) do |&block|
        allow(Redis).to receive(:new).with(url: "redis://custom:6379/0", timeout: 10).and_return(instance_double(Redis))
        block.call
      end.and_return(instance_double(ConnectionPool::Wrapper))

      lock_object.send(:redis_client)
      expect(ConnectionPool::Wrapper).to have_received(:new)
    end

    it "memoizes the redis client" do
      client1 = lock_object.send(:redis_client)
      client2 = lock_object.send(:redis_client)
      expect(client1).to be(client2)
    end

    it "returns a ConnectionPool::Wrapper instance" do
      expect(lock_object.send(:redis_client)).to be_a(Redis)
    end

    it "raises an error if Redis connection fails" do
      # Mock Redis.new
      allow(Redis).to receive(:new).and_raise(Redis::CannotConnectError, "Connection refused")
      allow(ConnectionPool::Wrapper).to receive(:new).and_yield.and_return(instance_double(ConnectionPool::Wrapper))
      expect do
        lock_object.send(:redis_client)
      end.to raise_error(RailsSoftLock::Error,
                         /Failed to connect to Redis: Connection refused/)
    end
  end

  describe "#locked_by" do
    context "when the object is locked" do
      before { lock_object.lock_or_find }

      it "returns the locker's ID" do
        expect(lock_object.locked_by).to eq(object_value)
      end
    end

    context "when the object is not locked" do
      it "returns nil" do
        expect(lock_object.locked_by).to be_nil
      end
    end
  end

  describe "#lock_or_find" do
    context "when the object is not locked" do
      let(:result) { lock_object.lock_or_find }

      it "locks the object" do
        expect(result[:locked_by]).to eq(object_value)
      end

      it "locks returns has_locked: false" do
        expect(result).to eq(has_locked: false, locked_by: object_value)
      end
    end

    context "when the object is already locked" do
      before { lock_object.lock_or_find }

      let(:new_lock) do
        described_class.new(object_name: object_name, object_key: object_key, object_value: "locker2")
      end

      it "does not lock" do
        new_lock = described_class.new(object_name: object_name, object_key: object_key, object_value: "locker2")
        new_lock.lock_or_find
        expect(lock_object.locked_by).to eq(object_value)
      end

      it "returns has_locked: true with existing locker" do
        result_new = new_lock.lock_or_find
        expect(result_new).to eq(has_locked: true, locked_by: object_value)
      end
    end
  end

  describe "#unlock" do
    context "when the object is locked" do
      before { lock_object.lock_or_find }

      it "unlocks the object" do
        lock_object.unlock
        expect(lock_object.locked_by).to be_nil
      end

      it "returns true" do
        expect(lock_object.unlock).to be true
      end
    end

    context "when the object is not locked" do
      it "returns false" do
        expect(lock_object.unlock).to be false
      end
    end
  end

  describe "#all_locks" do
    before do
      described_class.new(object_name: object_name, object_key: "key1", object_value: "value1").lock_or_find
      described_class.new(object_name: object_name, object_key: "key2", object_value: "value2").lock_or_find
    end

    it "returns all locks in the storage" do
      expect(lock_object.all_locks).to eq("key1" => "value1", "key2" => "value2")
    end

    context "when there are no locks" do
      before do
        redis = Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379/0")
        redis.del(object_name)
      end

      it "returns an empty hash" do
        expect(lock_object.all_locks).to eq({})
      end
    end
  end

  # rubocop:disable-next RSpec/MultipleMemoizedHelpers
  describe "TTL handling" do
    let(:redis) { Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379/0") }

    # HTTL returns an array (one entry per requested field); we always ask for one field
    def field_ttl
      redis.call("HTTL", object_name, "FIELDS", "1", object_key).first
    end

    context "with the default TTL" do
      it "sets the default TTL (12 hours) on the field" do
        lock_object.lock_or_find
        expect(field_ttl).to be_within(5).of(RailsSoftLock::RedisConfig::DEFAULT_TTL)
      end

      it "does not set a TTL on the hash key itself" do
        lock_object.lock_or_find
        expect(redis.ttl(object_name)).to eq(-1)
      end
    end

    context "when RAILS_SOFT_LOCK_TTL is set" do
      around do |example|
        ENV["RAILS_SOFT_LOCK_TTL"] = "60"
        example.run
        ENV.delete("RAILS_SOFT_LOCK_TTL")
      end

      it "applies the TTL from the environment variable" do
        lock_object.lock_or_find
        expect(field_ttl).to be_within(2).of(60)
      end
    end

    context "when ttl: 0 is passed explicitly" do
      let(:lock_object) do
        described_class.new(object_name: object_name, object_key: object_key,
                            object_value: object_value, ttl: 0)
      end

      it "does not set an expiration on the field" do
        lock_object.lock_or_find
        expect(field_ttl).to eq(-1)
      end
    end

    context "when a custom ttl is passed to the instance" do
      let(:lock_object) do
        described_class.new(object_name: object_name, object_key: object_key,
                            object_value: object_value, ttl: 120)
      end

      it "overrides the default/ENV TTL" do
        lock_object.lock_or_find
        expect(field_ttl).to be_within(2).of(120)
      end
    end

    context "with multiple locks in the same group" do
      let(:other_key) { "key2" }
      let(:other_lock) do
        described_class.new(object_name: object_name, object_key: other_key,
                            object_value: "locker2", ttl: 5)
      end

      it "only expires the field it was set on, not the whole group", :aggregate_failures do
        lock_object.lock_or_find # default 12h TTL on object_key
        other_lock.lock_or_find  # 5s TTL on other_key

        expect(field_ttl).to be_within(5).of(RailsSoftLock::RedisConfig::DEFAULT_TTL)
        other_field_ttl = redis.call("HTTL", object_name, "FIELDS", "1", other_key).first
        expect(other_field_ttl).to be_within(2).of(5)
      end
    end
  end
end
