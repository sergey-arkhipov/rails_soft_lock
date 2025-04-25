# frozen_string_literal: true

RSpec.describe RailsSoftLock do
  let(:object_name) { "test_locks" }
  let(:object_key) { "key1" }
  let(:object_value) { "locker1" }

  before do
    # Настраиваем конфигурацию для Redis
    described_class.configure do |config|
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
  end

  after do
    # Сбрасываем конфигурацию и lock_manager после каждого теста
    described_class.send(:reset_configuration)
    described_class.instance_variable_set(:@lock_manager, nil)
  end

  it "has a version number" do
    expect(RailsSoftLock::VERSION).not_to be_nil
  end

  describe ".configure" do
    it "yields a Configuration object" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(RailsSoftLock::Configuration)
    end

    context "when configuration is passed" do
      before do
        described_class.configure do |config|
          config.adapter = :redis
          config.adapter_options = { redis: { url: "redis://localhost:6379/0" } }
        end
      end

      it "sets the adapter" do
        expect(described_class.configuration.adapter).to eq(:redis)
      end

      it "sets theoptions" do
        expect(described_class.configuration.adapter_options).to eq(redis: { url: "redis://localhost:6379/0" })
      end
    end

    it "warns if no block is provided" do
      expect { described_class.configure }.to output(/No configuration block provided/).to_stderr
    end
  end

  # rubocop:disable RSpec/MultipleExpectations
  describe ".lock_manager" do
    it "returns a LockObject instance with correct parameters" do
      lock_manager = described_class.lock_manager(object_name: object_name, object_key: object_key,
                                                  object_value: object_value)
      expect(lock_manager).to be_a(RailsSoftLock::LockObject)
      expect(lock_manager.object_name).to eq(object_name)
      expect(lock_manager.object_key).to eq(object_key)
      expect(lock_manager.object_value).to eq(object_value)
    end

    # rubocop:enable RSpec/MultipleExpectations
    it "memoizes the LockObject instance for the same parameters" do
      lock_manager1 = described_class.lock_manager(object_name: object_name, object_key: object_key)
      lock_manager2 = described_class.lock_manager(object_name: object_name, object_key: object_key)
      expect(lock_manager1).to be(lock_manager2)
    end
  end
end
