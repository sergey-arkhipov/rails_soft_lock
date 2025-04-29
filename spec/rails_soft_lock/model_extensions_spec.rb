# frozen_string_literal: true

# spec/rails_soft_lock/model_extensions_spec.rb

require "spec_helper"
require "rails_soft_lock/model_extensions"
require "active_record"

# Fake model User
class User < ActiveRecord::Base
  self.table_name = "users"
end

# Test model with RailsSoftLock extension
class TestModel < ActiveRecord::Base
  self.table_name = "test_models"
  include RailsSoftLock::ModelExtensions
end

RSpec.describe RailsSoftLock::ModelExtensions do
  let(:user) { User.create! }
  let(:test_model) { TestModel.create!(lock_attribute: "test_key") }
  let(:object_name) { "TestModel::none" }
  let(:object_key) { "test_key" }
  let(:object_value) { user.id.to_s }

  before do
    # Setup Redis configuration
    RailsSoftLock.configure do |config|
      config.adapter = :redis
      config.adapter_options = {
        redis: {
          url: ENV["REDIS_URL"] || "redis://localhost:6379/0",
          timeout: 5
        }
      }
    end

    # Cleared Redis before each test
    Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379/0").del(object_name)

    # Setup acts_as_locked_by
    TestModel.acts_as_locked_by(:lock_attribute, scope: -> { "none" })
  end

  after do
    # Reset configuration after each test
    RailsSoftLock.send(:reset_configuration)
  end

  describe ".acts_as_locked_by" do
    it "sets locked attribute if provided" do
      TestModel.acts_as_locked_by(:custom_attr)
      expect(TestModel.locked_attribute).to eq(:custom_attr)
    end

    it "raises an error if attribute is not provided" do
      expect { TestModel.acts_as_locked_by }.to raise_error(
        RailsSoftLock::InvalidArgumentError,
        "[RailsSoftLock.acts_as_locked_by] Argument 'attribute' is required"
      )
    end

    it "sets locked scope if provided" do
      TestModel.acts_as_locked_by(:attribute, scope: -> { "custom_scope" })
      expect(TestModel.lock_scope_proc.call).to eq("custom_scope")
    end

    it "keeps default locked scope if none provided" do
      TestModel.acts_as_locked_by :attribute
      expect(TestModel.lock_scope_proc.call).to eq("none")
    end
  end

  describe ".object_name" do
    it "returns correct object name with default scope" do
      expect(TestModel.object_name).to eq("TestModel::none")
    end

    it "returns correct object name with custom scope" do
      TestModel.acts_as_locked_by(:attribute, scope: -> { "custom" })
      expect(TestModel.object_name).to eq("TestModel::custom")
    end
  end

  describe ".all_locks" do
    before { test_model.lock_or_find(user) }

    it "returns all existing locks" do
      expect(TestModel.all_locks).to eq({ object_key => user.id.to_s })
    end
  end

  describe ".unlock" do
    before { test_model.lock_or_find(user) }

    it "unlocks the specified object_key" do
      expect(TestModel.unlock(object_key)).to be true
    end

    it "does not unlock non-existent key" do
      expect(TestModel.unlock("non_existent")).to be false
    end
  end

  describe "#object_key" do
    it "returns the value of the locked attribute" do
      expect(test_model.object_key).to eq("test_key")
    end

    it "raises an error if no locked attribute is defined" do
      TestModel.acts_as_locked_by(:none)
      expect do
        test_model.object_key
      end.to raise_error(RailsSoftLock::NoMethodError,
                         "[RailsSoftLock.object_key] Model TestModel not respond to :none")
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
