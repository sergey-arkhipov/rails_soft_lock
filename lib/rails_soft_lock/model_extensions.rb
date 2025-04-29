# frozen_string_literal: true

# lib/rails_soft_lock/model_extensions.rb
module RailsSoftLock
  # Extend model and give methods from gem
  module ModelExtensions
    extend ActiveSupport::Concern

    included do
      class_attribute :locked_attribute, default: :id
      class_attribute :lock_scope_proc, default: -> { "none" }

      delegate :object_name, to: :class
    end

    class_methods do
      # Defines which attribute to use for locking and an optional scoping block.
      #
      # @param attribute [Symbol] the attribute used for locking (default: :id)
      # @param scope [Proc] a proc returning the scoping value (default: -> { "none" })
      # @return [void]
      def acts_as_locked_by(attribute = nil, scope: nil)
        self.locked_attribute = attribute if attribute
        self.lock_scope_proc  = scope if scope
      end

      # Fetches all locks for the model.
      #
      # @return [Hash]
      def all_locks
        RailsSoftLock::LockObject.new(object_name: object_name).all_locks
      end

      # Unlocks a specific object key.
      #
      # @param object_key [String, Integer]
      # @return [Boolean]
      def unlock(object_key)
        RailsSoftLock::LockObject.new(object_name: object_name, object_key: object_key).unlock
      end

      # Returns the composed object name (model + scope).
      #
      # @return [String]
      def object_name
        "#{name}::#{lock_scope_proc&.call}"
      end
    end

    # Attempts to acquire a lock for the given user.
    #
    # @param user [User]
    # @return [Hash]
    def lock_or_find(user)
      lock_object_for(user).lock_or_find
    end

    # Unlocks the object for the given user.
    #
    # @param user [User]
    # @return [Boolean]
    def unlock(user)
      lock_object_for(user).unlock
    end

    # Checks if the object is locked.
    #
    # @return [Boolean]
    def locked?
      locked_by.present?
    end

    # Returns the user who locked the object, if any.
    #
    # @return [User, nil]
    def locked_by
      user_id = base_lock_object.locked_by&.to_i
      user_id ? RailsSoftLock.configuration.locked_by_class.find_by(id: user_id) : nil
    end

    # Returns the lock attribute value for the instance.
    #
    # @return [Object]
    def object_key
      attribute = self.class.locked_attribute
      raise ArgumentError, "No locked attribute defined" if attribute == :none

      send(attribute)
    end

    private

    def lock_object_for(user)
      RailsSoftLock::LockObject.new(
        object_name: object_name,
        object_key: object_key,
        object_value: user.id.to_s
      )
    end

    def base_lock_object
      RailsSoftLock::LockObject.new(
        object_name: object_name,
        object_key: object_key
      )
    end
  end
end
