# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

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

  # Load rake task if Rails
  require "rails_soft_lock/railtie" if defined?(Rails)
end
