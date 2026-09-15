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
    # Note: field creation and TTL application are two separate Redis calls
    # (not a single atomic operation). In the rare case a process crashes
    # between them, the lock field would persist without a TTL. This is an
    # accepted trade-off: TTL here is a best-effort cleanup convenience, not
    # a strict consistency guarantee — a Redis restart/redeploy will clear
    # stale locks regardless. If atomicity becomes a hard requirement, see
    # HSETEX (Redis >= 8.0) or wrap creation+TTL in a Lua script (EVAL).

    def create
      created = create_field
      apply_ttl if created
      created # true on creation, false otherwise
    end

    # Updates the value for an existing key or creates a new key-value pair
    # @return [Boolean] true if the key was updated, false if it was created
    # @note TTL is intentionally NOT (re)applied here. This method is currently
    #   part of the adapter's generic interface but is not exposed through
    #   LockObject's public API (see LockObject#lock_or_find/#unlock/#all_locks).
    #   If it becomes user-facing, TTL handling should mirror #create — see the
    #   TTL trade-off note there before wiring it in.
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

    private

    def create_field
      redis_client.multi do |transaction|
        transaction.hsetnx(@object_name, @object_key, @object_value)
        transaction.hget(@object_name, @object_key)
      end.first
    end

    # Sets TTL on this specific hash field only, not on the whole group hash,
    # since @object_name can hold multiple unrelated locks as separate fields
    def apply_ttl
      return unless @ttl.to_i.positive?

      # HEXPIRE <key> <seconds> FIELDS <numfields> <field...>
      # Sets TTL on a single hash field (not the whole hash key), so that
      # unrelated locks sharing the same @object_name hash aren't affected.
      # Requires Redis/Valkey >= 7.4.
      redis_client.call("HEXPIRE", @object_name, @ttl.to_s, "FIELDS", "1", @object_key)
    end
  end
end
