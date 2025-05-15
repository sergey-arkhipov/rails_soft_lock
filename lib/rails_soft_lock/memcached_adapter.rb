# frozen_string_literal: true

# lib/rails_soft_lock/memcached_adapter.rb

require "dalli"
require "connection_pool"

# :reek:DuplicateMethodCall
module RailsSoftLock
  # Adapter for store lock in memcached
  module MemcachedAdapter
    # Initialize Memcached client
    # :reek:TooManyStatements
    def memcached_client
      client = exists_connection_for_namespace
      return client if client.present?

      ConnectionPool::Wrapper.new do
        Dalli::Client.new(RailsSoftLock.configuration.adapter_options.dig(:memcached, :servers) || "127.0.0.1:11211",
                          **RailsSoftLock.configuration.adapter_options.dig(:memcached, :options))
      end
    rescue Dalli::RingError => e
      raise RailsSoftLock::Error, "Failed to connect to Memcached: #{e.message}"
    end

    # Retrieves a value by key from the specified hash
    # @return [String, nil] The value associated with the key
    def get
      hash_value(:current)
    end

    # Creates a new key-value pair if the key does not exist
    # @return [Boolean] true if the key was created, false if it already existed
    def create
      result = memcached_client.add(object_key, build_data)
      update_used_keys(object_key)

      result.is_a?(Numeric)
    end

    # Updates the value for an existing key or creates a new key-value pair
    # @return [Boolean] true if the key was updated, false if it was created
    def update
      if updatable?
        memcached_client.set(object_key, build_data).present?
      else
        create
      end
    end

    # Deletes a key from the specified hash
    # @return [Boolean] true if the key was deleted, false if it did not exist
    def delete
      exists_keys = used_keys.get("keys")
      used_keys.replace("keys", exists_keys.reject { |key| key == object_key }) if exists_keys
      memcached_client.delete(object_key)
    end

    # Deletes all keys and their values from the current object
    # @return [Boolean]
    def purge
      memcached_client.flush
    end

    # Retrieves all key-value pairs in the specified hash
    # @return [Hash] The key-value pairs in the hash
    # rubocop:disable Style/HashTransformValues
    def all
      memcached_client.get_multi(*used_keys.get("keys")).each_with_object({}) do |(key, value), transformed_hash|
        transformed_hash[key] = value[:current]
      end
    end
    # rubocop:enable Style/HashTransformValues

    private

    # Checks the existing memcached connection for the specified object.
    # @return the Dalli::Client instance if found, otherwise nil
    def exists_connection_for_namespace
      # https://rubyapi.org/3.4/o/objectspace#method-c-each_object
      ObjectSpace.each_object(ConnectionPool::Wrapper) do |connection|
        return connection if connection.instance_variable_get(:@options)[:namespace] == object_name
      end
      nil
    end

    # Builds a storage format structure
    # @return [Hash]
    def build_data
      { current: object_value, previous: get }
    end

    # Fetches the value from the storage by key
    # @return [String] or nil
    def hash_value(key)
      data = memcached_client.get(object_key)
      data.fetch(key, nil) if data.is_a?(Hash)
    end

    # Defines the update condition for an object
    # @return [Boolean]
    def updatable?
      get != object_value || hash_value(:previous).present?
    end

    # Initialize the ConnectionInfo utility namespace, which stores a list of active memcached keys.
    # Returns Dalli::Client instance
    def used_keys
      # memcached ничего не знает про набор хранимых ключей в namespace,
      # т.е. здесь нельзя, как в Redis или NATS получить список ключей,
      # поэтому эта информация хранится в специальном служебном namespace "ConnectionInfo"
      @used_keys ||= ConnectionPool::Wrapper.new do
        options = RailsSoftLock.configuration.adapter_options.dig(:memcached,
                                                                  :options).merge({ namespace: "ConnectionInfo" })
        Dalli::Client.new(RailsSoftLock.configuration.adapter_options.dig(:memcached, :servers) || "127.0.0.1:11211",
                          **options)
      end
    end

    # Updates list of active memcached keys
    # @return the result of calling either 'add' or 'set' on the Dalli::Client instance
    # (depending on whether the key already exists)
    # :reek:NilCheck
    def update_used_keys(key)
      exists_keys = used_keys.get("keys")
      used_keys_value = [key].append(*exists_keys).uniq # rubocop:disable Rails/ActiveSupportAliases

      if exists_keys.nil?
        used_keys.add("keys", used_keys_value)
      else
        used_keys.set("keys", used_keys_value)
      end
    end
  end
end
