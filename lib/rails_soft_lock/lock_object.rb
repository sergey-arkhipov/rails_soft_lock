# frozen_string_literal: true

# lib/rails_soft_lock/lock_object.rb

module RailsSoftLock
  # Service for managing object locks
  # A lock object contains the following parameters:
  #   - object_name: The name of the lock storage, typically the model name with an optional scope
  #   - object_key: The identifier of the lock instance, typically a unique database record ID
  #   - object_value: The identifier of the locker that locked the record
  class LockObject
    # Maps adapter symbols to their respective modules
    ADAPTER_MAP = {
      redis: RailsSoftLock::RedisAdapter
      # nats: RailsSoftLock::NatsAdapter,
      # memcached: RailsSoftLock::MemcachedAdapter
    }.freeze

    # Selects and returns the adapter module based on current configuration.
    #
    # @return [Module] adapter module (e.g., RedisAdapter)
    # @raise [ArgumentError] if adapter is not recognized
    def self.adapter
      ADAPTER_MAP.fetch(RailsSoftLock.configuration.adapter) do |key|
        raise ArgumentError, "Unknown adapter: #{key}"
      end
    end

    include adapter

    attr_reader :object_name, :object_key, :object_value

    def initialize(object_name:, object_key: nil, object_value: nil)
      @object_name = object_name
      @object_key = object_key
      @object_value = object_value.present? ? object_value.to_s : nil # Convert to string for consistency
    end

    # Returns the ID of the locker who locked the object
    # @return [String, nil] The locker's ID or nil if not locked
    def locked_by
      get
    end

    # Attempts to lock the object or returns the existing lock
    # @return [Hash] { has_locked: Boolean, locked_by: String or nil }
    def lock_or_find
      locked_object = get
      { has_locked: !create, locked_by: locked_object || object_value }
    end

    # Unlocks the object
    # @return [Boolean] True if the lock was removed, false otherwise
    def unlock
      delete
    end

    # Returns all locks in the storage
    # @return [Hash] All key-value pairs in the storage
    def all_locks
      all
    end
  end
end
