# frozen_string_literal: true

# lib/rails_soft_lock/model_extensions.rb

module RailsSoftLock
  # Определяет настройки блокировки модели
  module ModelExtensions
    extend ActiveSupport::Concern

    class_methods do
      def acts_as_locked_by(attribute = :none)
        RailsSoftLock.configuration[:acts_as_locked_by] = attribute
      end

      def current_locked_attribute
        RailsSoftLock.configuration[:acts_as_locked_by]
      end

      def acts_as_locked_scope(attribute = nil)
        RailsSoftLock.configuration[:acts_as_locked_scope] = attribute || -> { "default" }
      end

      def current_locked_scope
        RailsSoftLock.configuration[:acts_as_locked_scope]
      end

      def all_locks
        RailsSoftLock::LockObject.new(object_name: object_name).all_locks
      end

      def unlock(object_key)
        RailsSoftLock::LockObject.new(object_name: object_name, object_key: object_key).unlock
      end

      def object_name
        scope = current_locked_scope&.call || "default"
        "#{name}-#{scope}"
      end
    end

    included do # rubocop:disable Metrics/BlockLength
      delegate :object_name, to: :class

      def lock_or_find(user)
        lock_object_for(user).lock_or_find
      end

      def unlock(user)
        lock_object_for(user).unlock
      end

      def locked?
        locked_by.present?
      end

      def locked_by
        user_id = base_lock_object.locked_by&.to_i
        user_id ? User.find_by(id: user_id) : nil
      end

      def object_key
        attribute = RailsSoftLock.configuration[:acts_as_locked_by]
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
end
