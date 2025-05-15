# frozen_string_literal: true

require "rails_soft_lock"
require "support/rails_soft_lock"
require "rails_soft_lock/shared_examples/adapter_example"
require "redis"
require "bundler/setup"
require "active_record"
require "support/active_record"
require "rake"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  # config.example_status_persistence_file_path = "spec/examples.txt"
  config.default_formatter = "doc" if config.files_to_run.one?

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Load Rake task
  config.before(:suite) do
    Rake::Task.define_task(:environment)
    load File.expand_path("../lib/tasks/rails_soft_lock.rake", __dir__)
  end

  config.after(:suite) do
    redis = Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379/0")
    redis.flushdb
  end
end
