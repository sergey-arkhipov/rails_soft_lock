# frozen_string_literal: true

# lib/rails_soft_lock/configuration.rb
module RailsSoftLock
  # Configuration class for RailsSoftLock gem.
  class Configuration
    # List of supported adapters.
    VALID_ADAPTERS = %i[redis nats memcached].freeze
    attr_reader :adapter
    # :reek:Attribute
    attr_accessor :adapter_options,
                  :acts_as_locked_by,
                  :acts_as_locked_scope

    attr_writer :locked_by_class

    def initialize
      @adapter = :redis # Default adapter
      @adapter_options = adapter_options || {} # Default adapter options
      @acts_as_locked_by = :none
      @acts_as_locked_scope = -> { "default" }
      @locked_by_class = locked_by_class || "User"
    end

    def locked_by_class
      @locked_by_class.is_a?(String) ? @locked_by_class.constantize : @locked_by_class
    end

    def [](key)
      send(key)
    end

    def []=(key, value)
      send("#{key}=", value)
    end

    # Sets the adapter and validates it.
    # @param value [Symbol] The adapter to use.
    # @raise [ArgumentError] If the adapter is not supported.
    def adapter=(value)
      raise ArgumentError, "Adapter must be one of: #{VALID_ADAPTERS.join(", ")}" unless VALID_ADAPTERS.include?(value)

      @adapter = value
    end
  end
end
