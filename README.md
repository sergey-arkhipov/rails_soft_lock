# RailsSoftLock – Group Locking for ApplicationRecord by Attribute

## Overview

The RailsSoftLock gem provides group-level locking for Rails ApplicationRecord objects based on a shared attribute. Instead of individually locking each database record (which can be expensive and complex), it creates and manages a single in-memory lock for the entire group via the attribute. This reduces database contention while maintaining thread safety.

### Key Features

    Lightweight Group Locking:

        Locks records sharing the same attribute value via an in-memory database (e.g., Redis, NATS).

        Avoids expensive row-level locks in your primary database.

    ActiveRecord Integration:

        Extends Rails’ built-in locking mechanisms with adapters for in-memory stores.

        Supports scoped uniqueness (e.g., lock groups by account_id + category).

    Beyond Locking:

        Can also mark/tag groups of records (e.g., flag all records with project_id=123 as "favorites").

        Useful for batch operations or state management (e.g., "processing", "archived").

### Current Status

    Active Development: New features and optimizations in progress.

    Available Adapters: Redis and Redis-compatible databases (e.g., Walkey).

## Installation

Install the gem and add to the application's Gemfile:

```bash
# Stable version
gem "rails_soft_lock"
# Last version
gem "rails_soft_lock", git: "https://github.com/sergey-arkhipov/rails_soft_lock.git"

```

When using Redis as an adapter and having REDIS_URL in config/redis.yml it is not necessary to install the initializer.
Only when need to replace some standard settings, User model, for example, or adapter.

```bash
bundle install
```

Run rake task

```bash
rake rails_soft_lock:install

```

This will install config for gem, if file does not exists

```ruby
## config/initializers/rails_soft_lock.rb
# frozen_string_literal: true

# Configuration for RailsSoftLock gem
# This file sets up the adapter and options for soft locking Active Record models
require "rails_soft_lock"
RailsSoftLock.configure do |config|
  # Specify the adapter for storing locks
  config.adapter = :redis

  # Configuration for the Redis adapter
  config.adapter_options = {
    redis: Rails.application.config_for(:redis).merge(
      timeout: 5
    )
  }
```

You can add any modification there.

Gem use ConnectionPool inside for safety connect to Redis adapter (now inplemented)

## Usage

Gem assumes that the User model is used to determine the user who sets the lock.

Another model for setting the attribute of the blocking user can be specified in the configuration.
The model ID is used for blocking.

```ruby
RailsSoftLock.configure do |config|
...
  # (Optional) Model class for locked_by lookups
  config.locked_by_class = "User"


end
```

Model < ApplicationRecord should include `RailsSoftLock::ModelExtensions`
and `acts_as_locked_by` with `acts_as_locked_scope` should be set, for example

```ruby
class Article < ApplicationRecord
  include RailsSoftLock::ModelExtensions

  acts_as_locked_by: attribyte, scope: -> { 'scope_result'}


```

See `spec/rails_soft_lock/model_extensions_spec.rb for implemented methods`

### Understanding the lock_or_find Method

The lock_or_find method returns a hash with the following structure:
ruby

{ has_locked: false, locked_by: user.id }

Key Points:

    has_locked: false indicates that the object was not locked prior to this operation.

        Note: This does not refer to the success/failure of the lock attempt itself.

    How locking works:

        Since this is an in-memory database designed for fast access, the method:

            Sets the lock (if no lock existed).

            Reports (has_locked: false) that no prior lock was present.

            Returns the ID of the user who now holds the lock.

        If the object was already locked, it returns:
        ruby

{ has_locked: true, locked_by: <existing_lock_user_id> }

In this case, the lock remains unchanged (no new lock is set).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rails_soft_lock. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/rails_soft_lock/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RailsSoftLock project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rails_soft_lock/blob/master/CODE_OF_CONDUCT.md).
