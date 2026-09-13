# frozen_string_literal: true

# spec/rails_soft_lock/install_spec.rb

require "spec_helper"
require "rails_soft_lock"
require "fileutils"
require "tmpdir"

# Mock Rails
module Rails
  def self.root
    Pathname.new(Dir.tmpdir)
  end

  def self.application
    @application ||= FakeApplication.new
  end

  # Simple stand-in for Rails.application, just enough for config_for
  class FakeApplication
    attr_writer :redis_config

    def config_for(_name)
      @redis_config || {}
    end
  end
end

RSpec.describe "RailsSoftLock Installation" do # rubocop:disable RSpec/DescribeClass
  let(:initializer_path) { File.join(Dir.tmpdir, "config", "initializers", "rails_soft_lock.rb") }
  let(:config_dir) { File.dirname(initializer_path) }

  before do
    # Create temp folder
    FileUtils.mkdir_p(config_dir)
    # Clear Rake task before each test
    Rake::Task.clear
    # Reload task prevent store in cache
    load File.expand_path("../../lib/tasks/rails_soft_lock.rake", __dir__)
    # Reset gem configuration before each test
    RailsSoftLock.send(:reset_configuration)
  end

  after do
    # Clear temp dir
    FileUtils.rm_rf(config_dir)
    # Reset gem configuration after each test
    RailsSoftLock.send(:reset_configuration)
  end

  describe "rake rails_soft_lock:install" do
    it "creates a configuration file if it does not exist" do # rubocop:disable RSpec/ExampleLength
      expect { Rake::Task["rails_soft_lock:install"].invoke }
        .to output(/Created RailsSoftLock configuration file/).to_stdout
        .and change { File.exist?(initializer_path) }.from(false).to(true)
        .and change { File.read(initializer_path) if File.exist?(initializer_path) }
        .from(nil)
        .to(
          include(
            "RailsSoftLock.configure do |config|",
            "config.adapter = :redis",
            "timeout: 5",
            ".except(:ttl)",
            "RAILS_SOFT_LOCK_TTL"
          )
        )
    end

    it "does not overwrite an existing configuration file", :aggregate_failures do
      original_content = "# Custom config\nRailsSoftLock.configure { |c| c.adapter = :memcached }"
      File.write(initializer_path, original_content)

      output = capture_output { Rake::Task["rails_soft_lock:install"].invoke }

      expect(output).to include("already exists")
      expect(File.read(initializer_path)).to eq(original_content)
    end
  end

  describe "configuration loading" do
    it "applies configuration from initializer", :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      stub_const("User", Class.new)
      # Prepare configuration
      config_content = <<~RUBY
        RailsSoftLock.configure do |config|
          config.adapter = :redis
          config.adapter_options = { redis: { url: "redis://localhost:6379/0", timeout: 5 } }
          config.locked_by_class = "User"
        end
      RUBY

      # Save and load confifuration
      File.write(initializer_path, config_content)
      load initializer_path

      # Check confifuration
      config = RailsSoftLock.configuration
      expect(config.adapter).to eq(:redis)
      expect(config.adapter_options).to eq(redis: { url: "redis://localhost:6379/0", timeout: 5 })
      expect(config.locked_by_class).to eq(User)
    end

    it "reads ttl from config/redis.yml via RedisConfig.default_ttl" do # rubocop:disable RSpec/ExampleLength
      config_content = <<~RUBY
        RailsSoftLock.configure do |config|
          config.adapter = :redis
          config.adapter_options = { redis: { url: "redis://localhost:6379/0", timeout: 5 } }
        end
      RUBY

      File.write(initializer_path, config_content)
      load initializer_path

      allow(Rails.application).to receive(:config_for).with(:redis).and_return(ttl: 120)
      expect(RailsSoftLock::RedisConfig.default_ttl).to eq(120)
    end
  end

  # Helper method for catch output
  # :reek:UtilityFunction
  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
