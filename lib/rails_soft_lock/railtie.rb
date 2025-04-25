# frozen_string_literal: true

# lib/rails_soft_lock/railtie.rb

module RailsSoftLock
  # Load rails_soft_lock:install
  # After load rails rails_soft_lock:install check config/initializers/rails_soft_lock.rb
  # and create initializer if do not exists
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/rails_soft_lock.rake"
    end
  end
end
