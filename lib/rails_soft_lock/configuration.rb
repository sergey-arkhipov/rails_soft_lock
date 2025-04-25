# frozen_string_literal: true

# lib/rails_soft_lock/configuration.rb
module RailsSoftLock
  # Configuration class for RailsSoftLock gem.
  class Configuration
    # List of supported adapters.
    VALID_ADAPTERS = %i[redis nats memcached].freeze
    attr_reader :adapter
    attr_accessor :adapter_options, :acts_as_locked_by, :acts_as_locked_scope

    def initialize
      @adapter = :redis # Default adapter
      @adapter_options = adapter_options || {} # Default adapter options
      @acts_as_locked_by = :none
      @acts_as_locked_scope = -> { "default" }
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

  class << self
    # Configures the RailsSoftLock gem with a block.
    # @yield [config] Yields the configuration object to the block.
    # @return [void]
    def configure
      @configuration ||= Configuration.new
      if block_given?
        yield(@configuration)
      else
        warn "[RailsSoftLock] No configuration block provided in `configure`"
      end
    end

    # Returns the current configuration instance.
    # @return [Configuration] The configuration object.
    def configuration
      @configuration ||= Configuration.new
    end

    # Resets the configuration (useful for testing).
    # @return [void]
    def reset_configuration
      @configuration = nil
    end
  end
end
