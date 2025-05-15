# frozen_string_literal: true

# spec/rails_soft_lock/memcached_adapter_spec.rb

require "spec_helper"
require "rails_soft_lock/memcached_adapter"

# Test class for MemcachedAdapter
class MemcachedAdapterTest
  include RailsSoftLock::MemcachedAdapter

  # :reek:Attribute
  attr_accessor :object_name, :object_key, :object_value

  def initialize(object_name:, object_key:, object_value:)
    @object_name = object_name
    @object_key = object_key
    @object_value = object_value
  end
end

# A structure  that defines the parameters of a locking object
Params = Struct.new(:name, :key, :value)

RSpec.describe RailsSoftLock::MemcachedAdapter do
  let(:object_params) { Params.new("test_locks", "key1", "value1") }
  let(:options) { { servers: ENV["MEMCACHED_URL"] || "127.0.0.1:11211", options: { namespace: "test-model" } } }
  let(:adapter) do
    MemcachedAdapterTest.new(object_name: object_params.name,
                             object_key: object_params.key,
                             object_value: object_params.value)
  end

  before do
    # Set test config
    RailsSoftLock.configure do |config|
      config.adapter = :memcached
      config.adapter_options = { memcached: options }
    end
  end

  after do
    # Reset config after test
    RailsSoftLock.send(:reset_configuration)
  end

  describe "#memcached_client" do
    context "when pass configuration" do
      before do
        allow(ConnectionPool::Wrapper).to receive(:new) do |&block|
          # Два метода alllow чтобы избежать ошибки
          # "Please stub a default value first if message might be received with other args as well"
          allow(Dalli::Client).to receive(:new).with("127.0.0.1:11211").and_return(instance_double(Dalli::Client))
          allow(Dalli::Client).to receive(:new).with("127.0.0.1:11211", **options[:options])
                              .and_return(instance_double(Dalli::Client))
          block.call
        end.and_return(instance_double(ConnectionPool::Wrapper))
      end

      it "creates a ConnectionPool::Wrapper with configured options" do
        adapter.memcached_client
        expect(ConnectionPool::Wrapper).to have_received(:new)
      end

      it "uses default options if configuration is empty" do
        RailsSoftLock.configure do |config|
          config.adapter = :memcached
          config.adapter_options = {}
        end

        adapter.memcached_client
        expect(ConnectionPool::Wrapper).to have_received(:new)
      end
    end
  end

  it_behaves_like "adapter instance methods", MemcachedAdapterTest, Params.new("test_locks", "key1", "value1")
end
