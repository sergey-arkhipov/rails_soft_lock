# frozen_string_literal: true

# spec/rails_soft_lock/redis_adapter_spec.rb

require "spec_helper"
require "rails_soft_lock/redis_adapter"

# Test class for RedisAdapter
class RedisAdapterTest
  include RailsSoftLock::RedisAdapter

  # :reek:Attribute
  attr_accessor :object_name, :object_key, :object_value

  def initialize
    @object_name = "test_locks"
    @object_key = "key1"
    @object_value = "value1"
  end
end

RSpec.describe RailsSoftLock::RedisAdapter do
  let(:options) { { url: ENV["REDIS_URL"] || "redis://localhost:6379/0", timeout: 5 } }
  let(:adapter) { RedisAdapterTest.new }
  let(:object_name) { "test_locks" }
  let(:object_key) { "key1" }
  let(:object_value) { "value1" }

  before do
    # Set test config
    RailsSoftLock.configure do |config|
      config.adapter = :redis
      config.adapter_options = { redis: options }
    end
    # Reset Redis using different client
    redis = Redis.new(url: options[:url], timeout: options[:timeout])
    redis.del(object_name)
    # Reset memoize redis_client
    adapter.instance_variable_set(:@redis_client, nil)
  end

  after do
    # Reset config after test
    RailsSoftLock.send(:reset_configuration)
  end

  describe "#redis_client" do
    context "when pass configuration" do
      before do
        allow(ConnectionPool::Wrapper).to receive(:new) do |&block|
          allow(Redis).to receive(:new).with(url: "redis://localhost:6379/0",
                                             timeout: 5).and_return(instance_double(Redis))
          block.call
        end.and_return(instance_double(ConnectionPool::Wrapper))
      end

      it "creates a ConnectionPool::Wrapper with configured options" do
        adapter.redis_client
        expect(ConnectionPool::Wrapper).to have_received(:new)
      end

      it "uses default options if configuration is empty" do
        RailsSoftLock.configure do |config|
          config.adapter = :redis
          config.adapter_options = {}
        end

        adapter.redis_client

        expect(ConnectionPool::Wrapper).to have_received(:new)
      end
    end

    it "memoizes the Redis client" do
      client1 = adapter.redis_client
      client2 = adapter.redis_client
      expect(client1).to be(client2)
    end
  end

  describe "#get" do
    context "when the key exists" do
      before { adapter.create }

      it "returns the value for the key" do
        expect(adapter.get).to eq(object_value)
      end
    end

    context "when the key does not exist" do
      before { adapter.object_key = "nonexistent_key" }

      it "returns nil" do
        expect(adapter.get).to be_nil
      end
    end
  end

  describe "#create" do
    context "when the key does not exist" do
      it "creates the key-value pair" do
        adapter.create
        expect(adapter.get).to eq(object_value)
      end

      it "returns false about existence pair" do
        expect(adapter.create).to be false
      end
    end

    context "when the key already exists" do
      before { adapter.create }

      it "does not overwrite the value" do
        adapter.object_value = "new_value"
        expect(adapter.get).to eq(object_value)
      end

      it "returns true" do
        adapter.object_value = "new_value"
        expect(adapter.create).to be true
      end
    end
  end

  describe "#update" do
    context "when the key exists" do
      before { adapter.create }

      it "updates the value" do
        adapter.object_value = "new_value"
        adapter.update
        expect(adapter.get).to eq("new_value")
      end

      it "returns true" do
        adapter.object_value = "new_value"
        expect(adapter.update).to be true
      end
    end

    context "when the key does not exist" do
      it "creates the key-value pair" do
        adapter.update
        expect(adapter.get).to eq(object_value)
      end

      it "returns false, because there was create action" do
        expect(adapter.update).to be false
      end
    end
  end

  describe "#delete" do
    context "when the key exists" do
      before { adapter.create }

      it "deletes the key" do
        adapter.delete
        expect(adapter.get).to be_nil
      end

      it "returns true" do
        expect(adapter.delete).to be true
      end
    end

    context "when the key does not exist" do
      it "returns false" do
        expect(adapter.delete).to be false
      end
    end
  end

  describe "#all" do
    before do
      adapter.object_key = "key1"
      adapter.object_value = "value1"
      adapter.create
      adapter.object_key = "key2"
      adapter.object_value = "value2"
      adapter.create
    end

    it "returns all key-value pairs in the hash" do
      expect(adapter.all).to eq("key1" => "value1", "key2" => "value2")
    end

    context "when the hash is empty" do
      before do
        redis = Redis.new(url: options[:url], timeout: options[:timeout])
        redis.del(object_name)
      end

      it "returns an empty hash" do
        expect(adapter.all).to eq({})
      end
    end
  end
end
