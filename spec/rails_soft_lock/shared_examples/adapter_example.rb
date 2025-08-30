# frozen_string_literal: true

# spec/rails_soft_lock/shared_examples/adapter_example.rb

RSpec.shared_examples "adapter instance methods" do |adapter_class, object_params|
  let(:adapter) do
    adapter_class.new(object_name: object_params.name,
                      object_key: object_params.key,
                      object_value: object_params.value)
  end

  describe "#get" do
    context "when the key exists" do
      before { adapter.create }

      it "returns the value for the key" do
        expect(adapter.get).to eq(object_params.value)
      end
    end

    context "when the key does not exist" do
      before { adapter.object_key = "nonexistent_key" }

      it "returns nil" do
        expect(adapter.get).to be_nil
      end
    end
  end

  describe "#create" do
    context "when the key does not exist" do
      before { adapter.delete }

      it "returns true if creates the key-value pair succeeded" do # rubocop:disable RSpec/MultipleExpectations
        result = adapter.create
        expect(adapter.get).to eq(object_params.value)
        expect(result).to be true
      end

      it "returns false about existence pair" do
        adapter.create
        expect(adapter.create).to be false
      end
    end

    context "when the key already exists" do
      before { adapter.create }

      it "does not overwrite the value" do
        adapter.object_value = "new_value"
        adapter.create
        expect(adapter.get).to eq(object_params.value)
      end

      it "returns false" do
        adapter.object_value = "new_value"
        expect(adapter.create).to be false
      end
    end
  end

  describe "#update" do
    context "when the key exists" do
      before { adapter.create }

      it "updates the value" do
        adapter.object_value = "new_value"
        adapter.update
        expect(adapter.get).to eq("new_value")
      end

      it "returns true" do
        adapter.object_value = "new_value"
        expect(adapter.update).to be true
      end
    end

    context "when the key does not exist" do
      it "creates the key-value pair" do
        adapter.delete
        adapter.update
        expect(adapter.get).to eq(object_params.value)
      end

      it "returns false, because there was create action" do
        expect(adapter.update).to be false
      end
    end
  end

  describe "#delete" do
    context "when the key exists" do
      before { adapter.create }

      it "deletes the key" do
        adapter.delete
        expect(adapter.get).to be_nil
      end

      it "returns true" do
        expect(adapter.delete).to be true
      end
    end

    context "when the key does not exist" do
      it "returns false" do
        expect(adapter.delete).to be false
      end
    end
  end

  describe "#all" do
    before do
      adapter.object_key = "key1"
      adapter.object_value = "value1"
      adapter.create
      adapter.object_key = "key2"
      adapter.object_value = "value2"
      adapter.create
    end

    it "returns all key-value pairs in the hash" do
      expect(adapter.all).to eq("key1" => "value1", "key2" => "value2")
    end

    context "when the hash is empty" do
      before { adapter.purge }

      it "returns an empty hash" do
        expect(adapter.all).to eq({})
      end
    end
  end
end
