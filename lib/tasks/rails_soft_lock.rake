# frozen_string_literal: true

# lib/tasks/rails_soft_lock.rake

namespace :rails_soft_lock do
  desc "Generate a RailsSoftLock configuration file in config/initializers"
  task :install do # rubocop:disable Rails/RakeEnvironment
    initializer_path = Rails.root.join("config/initializers/rails_soft_lock.rb")

    if File.exist?(initializer_path)
      puts "RailsSoftLock configuration file already exists at #{initializer_path}"
    else
      File.write(initializer_path, <<~RUBY)
              # frozen_string_literal: true

              # Configuration for RailsSoftLock gem
              # This file sets up the adapter and options for soft locking Active Record models

              RailsSoftLock.configure do |config|
                # Specify the adapter for storing locks
                config.adapter = :redis

        # configuration for the redis adapter
        config.adapter_options = {
          redis: rails.application.config_for(:redis).merge(
            timeout: 5
          )
        }

                # (Optional) Attribute used for locking
                # config.acts_as_locked_by = :lock_attribute

                # (Optional) Scope for separating locks
                # config.acts_as_locked_scope = -> { "default_scope" }

                # (Optional) Model class for locked_by lookups
                # config.locked_by_class = User
              end
      RUBY
      puts "Created RailsSoftLock configuration file at #{initializer_path}"
    end
  end
end
