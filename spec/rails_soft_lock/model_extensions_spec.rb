# frozen_string_literal: true

# spec/rails_soft_lock/model_extensions_spec.rb

require "spec_helper"
require "rails_soft_lock/model_extensions"
require "active_record"

# Fake model User
class User < ActiveRecord::Base
  self.table_name = "users"
end

# Test model ModelExtensions
class TestModel < ActiveRecord::Base
  self.table_name = "test_models"
  include RailsSoftLock::ModelExtensions
end

RSpec.describe RailsSoftLock::ModelExtensions do
  let(:user) { User.create! }
  let(:test_model) { TestModel.create!(lock_attribute: "test_key") }
  let(:object_name) { "TestModel-default" }
  let(:object_key) { "test_key" }
  let(:object_value) { user.id.to_s }

  before do
    # Настраиваем конфигурацию для Redis
    RailsSoftLock.configure do |config|
      config.adapter = :redis
      config.adapter_options = {
        redis: {
          url: ENV["REDIS_URL"] || "redis://localhost:6379/0",
          timeout: 5
        }
      }
    end

    # Очищаем Redis перед каждым тестом
    redis = Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379/0")
    redis.del(object_name)

    # Настраиваем acts_as_locked_by
    TestModel.acts_as_locked_by(:lock_attribute)
  end

  after do
    # Сбрасываем конфигурацию после каждого теста
    RailsSoftLock.send(:reset_configuration)
  end

  describe ".acts_as_locked_by" do
    it "sets the locked attribute in configuration" do
      TestModel.acts_as_locked_by(:lock_attribute)
      expect(TestModel.current_locked_attribute).to eq(:lock_attribute)
    end
  end

  describe ".current_locked_attribute" do
    it "returns the configured locked attribute" do
      expect(TestModel.current_locked_attribute).to eq(:lock_attribute)
    end
  end

  describe ".acts_as_locked_scope" do
    it "sets the locked scope in configuration" do
      scope = -> { "custom_scope" }
      TestModel.acts_as_locked_scope(scope)
      expect(TestModel.current_locked_scope).to eq(scope)
    end

    it "sets default scope if no argument provided" do
      TestModel.acts_as_locked_scope
      expect(TestModel.current_locked_scope.call).to eq("default")
    end
  end

  describe ".current_locked_scope" do
    it "returns the configured locked scope" do
      scope = -> { "custom_scope" }
      TestModel.acts_as_locked_scope(scope)
      expect(TestModel.current_locked_scope.call).to eq("custom_scope")
    end
  end

  describe ".object_name" do
    it "returns the model name with default scope" do
      expect(TestModel.object_name).to eq("TestModel-default")
    end

    it "returns the model name with custom scope" do
      TestModel.acts_as_locked_scope(-> { "custom" })
      expect(TestModel.object_name).to eq("TestModel-custom")
    end
  end

  describe ".all_locks" do
    before do
      RailsSoftLock::LockObject.new(
        object_name: object_name,
        object_key: "key1",
        object_value: user.id.to_s
      ).lock_or_find
    end

    it "returns all locks for the model" do
      expect(TestModel.all_locks).to eq("key1" => user.id.to_s)
    end
  end

  describe ".unlock" do
    before do
      RailsSoftLock::LockObject.new(
        object_name: object_name,
        object_key: object_key,
        object_value: user.id.to_s
      ).lock_or_find
    end

    it "unlocks the specified key", :aggregate_failures do
      result = TestModel.unlock(object_key)
      lock_status = RailsSoftLock::LockObject.new(object_name: object_name, object_key: object_key).locked_by

      expect(result).to be true
      expect(lock_status).to be_nil
    end
  end

  describe "#object_key" do
    it "returns the value of the locked attribute" do
      expect(test_model.object_key).to eq("test_key")
    end

    it "raises an error if no locked attribute is defined" do
      TestModel.acts_as_locked_by(:none)
      expect { test_model.object_key }.to raise_error(ArgumentError, "No locked attribute defined")
    end
  end

  describe "#lock_or_find" do
    context "when the object is not locked" do
      it "locks the object and returns has_locked: true", :aggregate_failures do
        result = test_model.lock_or_find(user)
        expect(result).to eq(has_locked: false, locked_by: user.id.to_s)
        expect(test_model.locked_by).to eq(user)
      end
    end

    context "when the object is already locked" do
      before do
        test_model.lock_or_find(user)
      end

      it "returns has_locked: false with existing locker", :aggregate_failures do
        new_user = User.create!
        result = test_model.lock_or_find(new_user)
        expect(result).to eq(has_locked: true, locked_by: user.id.to_s)
        expect(test_model.locked_by).to eq(user)
      end
    end
  end

  describe "#unlock" do
    context "when the object is locked" do
      before { test_model.lock_or_find(user) }

      it "unlocks the object and returns true", :aggregate_failures do
        expect(test_model.unlock(user)).to be true
        expect(test_model.locked?).to be false
      end
    end

    context "when the object is not locked" do
      it "returns false" do
        expect(test_model.unlock(user)).to be false
      end
    end
  end

  describe "#locked?" do
    context "when the object is locked" do
      before { test_model.lock_or_find(user) }

      it "returns true" do
        expect(test_model.locked?).to be true
      end
    end

    context "when the object is not locked" do
      it "returns false" do
        expect(test_model.locked?).to be false
      end
    end
  end

  describe "#locked_by" do
    context "when the object is locked" do
      before { test_model.lock_or_find(user) }

      it "returns the user who locked the object" do
        expect(test_model.locked_by).to eq(user)
      end
    end

    context "when the object is not locked" do
      it "returns nil" do
        expect(test_model.locked_by).to be_nil
      end
    end
  end
end
