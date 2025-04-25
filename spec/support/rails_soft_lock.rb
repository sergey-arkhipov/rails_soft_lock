# frozen_string_literal: true

RailsSoftLock.configure do |config|
  config.adapter = :redis
  config.adapter_options = {
    redis: {
      url: ENV["REDIS_URL"] || "redis://localhost:6379/0",
      timeout: 5
    }
  }
end
