# frozen_string_literal: true

# lib/rails_soft_lock/configuration.rb
module RailsSoftLock
  # Configuration for global settings like adapter and user class.
  class Configuration
    # Supported storage adapters.
    VALID_ADAPTERS = %i[redis nats memcached].freeze

    attr_reader :adapter, :adapter_options
    # :reek:Attribute
    attr_writer :locked_by_class

    # Initializes configuration with default values.
    def initialize
      @adapter = :redis
      @adapter_options = RedisConfig.default_adapter_options
      @locked_by_class = locked_by_class || "User"
    end

    def adapter_options=(options = {})
      @adapter_options = options.empty? ? RedisConfig.default_adapter_options : options
    end

    # Returns the locker class constant (e.g., User).
    #
    # @return [Class]
    def locked_by_class
      @locked_by_class.is_a?(String) ? @locked_by_class.constantize : @locked_by_class
    end

    # Sets the adapter (e.g., :redis, :nats, :memcached).
    #
    # @param value [Symbol] one of the VALID_ADAPTERS
    # @raise [ArgumentError] if adapter is not valid
    # @return [void]
    def adapter=(value)
      raise ArgumentError, "Adapter must be one of: #{VALID_ADAPTERS.join(", ")}" unless VALID_ADAPTERS.include?(value)

      @adapter = value
    end
  end
end
