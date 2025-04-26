# frozen_string_literal: true

# lib/rails_soft_lock.rb

require "zeitwerk"

# RailsSoftLock - module for soft lock ApplicationRecord by attribyte
module RailsSoftLock
  # Error class for gem
  class Error < StandardError; end

  def self.lock_manager(object_name:, object_key: nil, object_value: nil)
    @lock_manager ||= LockObject.new(
      object_name: object_name,
      object_key: object_key,
      object_value: object_value
    )
  end

  # Pass methods to adapter
  def self.get(object_name, object_key)
    lock_manager(object_name: object_name, object_key: object_key).locked_by
  end

  def self.create(object_name, object_key, object_value)
    lock_manager(object_name: object_name, object_key: object_key, object_value: object_value).lock_or_find
  end

  def self.update(object_name, object_key, object_value)
    lock_manager(object_name: object_name, object_key: object_key, object_value: object_value).lock_or_find
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

  # Load rake task if Rails
  require "rails_soft_lock/railtie" if defined?(Rails)
end

loader = Zeitwerk::Loader.for_gem
loader.setup
