# frozen_string_literal: true

# lib/rails_soft_lock/redis_adapter.rb

require "redis"
require "connection_pool"

module RailsSoftLock
  # Adapter for store lock in redis
  module RedisAdapter
    # Initialize Redis client
    def redis_client
      @redis_client ||= begin
        ConnectionPool::Wrapper.new { Redis.new(**RailsSoftLock.configuration.adapter_options[:redis]) }
      rescue Redis::CannotConnectError => e
        raise RailsSoftLock::Error, "Failed to connect to Redis: #{e.message}"
      end
    end

    # Retrieves a value by key from the specified hash
    # @return [String, nil] The value associated with the key
    def get
      redis_client.hget(@object_name, @object_key)
    end

    # Creates a new key-value pair if the key does not exist
    # @return [Boolean] true if the key was created, false if it already existed
    def create
      result = redis_client.multi do |transaction|
        transaction.hsetnx(@object_name, @object_key, @object_value)
        transaction.hget(@object_name, @object_key)
      end
      result.first # true on creation, false otherwise
    end

    # Updates the value for an existing key or creates a new key-value pair
    # @return [Boolean] true if the key was updated, false if it was created
    def update # rubocop:disable Naming/PredicateMethod
      result = redis_client.hset(@object_name, @object_key, @object_value)
      result.zero?
    end

    # Deletes a key from the specified hash
    # @return [Boolean] true if the key was deleted, false if it did not exist
    def delete # rubocop:disable Naming/PredicateMethod
      result = redis_client.hdel(@object_name, @object_key)
      !result.zero?
    end

    # Retrieves all key-value pairs in the specified hash
    # @return [Hash] The key-value pairs in the hash
    def all
      redis_client.hgetall(@object_name)
    end
  end
end
