# frozen_string_literal: true

# spec/support/active_record.rb

require "active_record"

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

# Создаём таблицы для User и TestModel
ActiveRecord::Schema.define do
  create_table :users, force: true, &:timestamps

  create_table :test_models, force: true do |t|
    t.string :lock_attribute
    t.timestamps
  end
end
