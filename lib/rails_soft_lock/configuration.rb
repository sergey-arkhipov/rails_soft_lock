# frozen_string_literal: true

# lib/rails_soft_lock/configuration.rb
module RailsSoftLock
  # Configuration class for RailsSoftLock gem.
  class Configuration
    # List of supported lock storage adapters
    VALID_ADAPTERS          = %i[redis nats memcached].freeze
    # Default class used as the "locker" (usually a User model)
    DEFAULT_LOCKED_BY_CLASS = "User"
    # Default options for acts_as_locked_by DSL
    DEFAULT_LOCKED_OPTIONS  = { by: :lock_attribute, scope: -> { "none" } }.freeze

    attr_reader :adapter
    # :reek:Attribute
    attr_accessor :adapter_options
    # :reek:Attribute
    attr_writer :locked_by_class

    # Initializes configuration with default values.
    def initialize
      @adapter                = :redis # Default adapter
      @adapter_options      ||= RedisConfig.default_adapter_options # Default adapter options
      @locked_by_class        = DEFAULT_LOCKED_BY_CLASS
      @acts_as_locked_options = DEFAULT_LOCKED_OPTIONS.dup
    end

    # DSL to define the attribute used as lock key and the scoping logic.
    #
    # @param attribute [Symbol] the attribute name to lock by (e.g., :id, :article_code)
    # @param scope [Proc] a lambda that returns a scoping key (e.g., tenant_id)
    # @return [void]
    def acts_as_locked_by(attribute = nil, scope: nil)
      options = {}
      options[:by] = attribute if attribute
      options[:scope] = scope if scope

      @acts_as_locked_options = DEFAULT_LOCKED_OPTIONS.merge(options)
    end

    # Returns the attribute used to identify lock ownership.
    #
    # @return [Symbol]
    def acts_as_locked_attribute
      @acts_as_locked_options&.[](:by)
    end

    # Returns the evaluated scope value, typically a tenant ID or similar.
    #
    # @return [Object] result of the scope lambda or "none"
    def acts_as_locked_scope
      @acts_as_locked_options&.[](:scope)&.call
    end

    # Returns the class used to represent the locker (usually a User model).
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
