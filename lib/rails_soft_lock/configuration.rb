# frozen_string_literal: true

# lib/rails_soft_lock/configuration.rb
module RailsSoftLock
  # Configuration class for RailsSoftLock gem.
  class Configuration
    # List of supported adapters.
    VALID_ADAPTERS = %i[redis nats memcached].freeze
    attr_reader :adapter
    # :reek:Attribute
    attr_accessor :adapter_options

    # :reek:Attribute
    attr_writer :locked_by_class

    def initialize
      @adapter = :redis # Default adapter
      @adapter_options = adapter_options || {} # Default adapter options
      @locked_by_class = locked_by_class || "User"
    end

    def acts_as_locked_by(attribute = :lock_attribute, scope: -> { "none" })
      @acts_as_locked_options = { by: attribute, scope: scope }
    end

    def acts_as_locked_attribute
      @acts_as_locked_options&.[](:by) || :lock_attribute
    end

    def acts_as_locked_scope
      @acts_as_locked_options&.[](:scope)&.call || "none"
    end

    def locked_by_class
      @locked_by_class.is_a?(String) ? @locked_by_class.constantize : @locked_by_class
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
