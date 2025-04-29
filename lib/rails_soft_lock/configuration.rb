# frozen_string_literal: true

# lib/rails_soft_lock/configuration.rb
module RailsSoftLock
  # Configuration for global settings like adapter and user class.
  class Configuration
    # Supported storage adapters.
    VALID_ADAPTERS = %i[redis nats memcached].freeze

    attr_reader :adapter
    # :reek:Attribute
    attr_accessor :adapter_options
    # :reek:Attribute
    attr_writer :locked_by_class

    def initialize
      @adapter = :redis
      @adapter_options ||= RedisConfig.default_adapter_options
      @locked_by_class = locked_by_class || "User"
    end

    # Returns the locker class constant (e.g., User).
    #
    # @return [Class]
    def locked_by_class
      @locked_by_class.is_a?(String) ? @locked_by_class.constantize : @locked_by_class
    end

    # Sets the adapter for lock storage.
    #
    # @param value [Symbol] one of the VALID_ADAPTERS
    # @raise [ArgumentError] if adapter is invalid
    # @return [void]
    def adapter=(value)
      raise ArgumentError, "Adapter must be one of: #{VALID_ADAPTERS.join(", ")}" unless VALID_ADAPTERS.include?(value)

      @adapter = value
    end
  end
end
