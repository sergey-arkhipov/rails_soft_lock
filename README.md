# RailsSoftLock

This gem implements the ability to lock Rails Active Records using adapters for in-memory databases, such as redis, nats, etc.
Locks can be done by using the active record attribute.
it is possible to define the uniqueness scope of the attribute.
The gem is under active development.
Currently, an adapter to redis-compatible databases, such as redis, walkey, etc., has been implemented.

## Installation

Install the gem and add to the application's Gemfile:

```bash
gem "rails_soft_lock", git: "https://github.com/sergey-arkhipov/rails_soft_lock.git"

```

After run

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
The model ID is used for blocking

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

  acts_as_locked_by(:attribyte)
  acts_as_locked_scope(proc { :scoped_attribute || "none" })

```

See `spec/rails_soft_lock/model_extensions_spec.rb for implemented methods`

### Attention

Pay attention how method `locak_or_find` work

Method return hash
`has_locked: false, locked_by: user.id`

`has_lock`: false implies that there was no lock on the passed object before this point.
Not to be confused with the result of executing the lock itself.
Since this is an in-memory base and the goal is quick and easy access, the method sets the lock,
reports that there was no lock before, and returns the user of the lock.
If there was a lock, true is returned and the user of this current lock.
The lock itself is not changed.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rails_soft_lock. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/rails_soft_lock/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RailsSoftLock project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rails_soft_lock/blob/master/CODE_OF_CONDUCT.md).
