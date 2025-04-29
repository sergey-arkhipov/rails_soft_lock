# frozen_string_literal: true

# lib/rails_soft_lock/redis_config.rb
module RailsSoftLock
  # Provides Redis configuration management for RailsSoftLock gem
  # Handles:
  # - Default Redis settings
  # - Rails-specific configuration lookup
  # - Safe fallbacks when Rails isn't available
  module RedisConfig
    module_function

    # Returns the complete Redis adapter options hash
    # @return [Hash] Options hash with :redis key containing configuration
    # @example
    #   { redis: { host: 'localhost', port: 6379, db: 0, timeout: 5 } }
    def default_adapter_options
      { redis: config_with_defaults }
    end

    # Merges default settings with any Rails-specific configuration
    # @return [Hash] Complete Redis configuration
    # @note Will return just defaults if Rails isn't available
    def config_with_defaults
      base_config = rails_available? ? rails_config : {}
      default_settings.merge(base_config)
    end

    # Checks if Rails environment is available and properly configured
    # @return [Boolean]
    def rails_available?
      !!(defined?(Rails) && Rails.try(:application).present?)
    end

    # Attempts to load Redis config from Rails application
    # @return [Hash] Redis configuration from Rails or empty hash if unavailable
    # @note Safely handles cases where config_for isn't available
    def rails_config
      return {} unless rails_config_available?

      config = Rails.application.config_for(:redis)

      config.is_a?(Hash) ? config.symbolize_keys : {}
    rescue RuntimeError, ArgumentError
      {}
    end

    # Checks if Rails provides config_for functionality
    # @return [Boolean]
    # @api private
    def rails_config_available?
      !!Rails.application.try(:config_for)
    end

    # The default Redis connection settings
    # @return [Hash]
    # @api private
    def default_settings
      { url: "redis://localhost:6379/0", timeout: 5 }
    end
  end
end
