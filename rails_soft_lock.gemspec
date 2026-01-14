# frozen_string_literal: true

require File.expand_path("lib/rails_soft_lock/version", __dir__)

Gem::Specification.new do |spec|
  spec.name = "rails_soft_lock"
  spec.version = RailsSoftLock::VERSION
  spec.authors = ["Sergey Arkhipov", "Georgy Shcherbakov", "Vladimir Peskov"]
  spec.email = ["sergey-arkhipov@ya.ru", "lordsynergymail@gmail.com", "v.peskov@mail.ru"]

  spec.summary = "Lock Active record by attribyte using in-memory adapters"
  spec.description = "Using In-Memory Databases to Work with Rails Active Record Locks"
  spec.homepage = "https://github.com/sergey-arkhipov/rails_soft_lock"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "lib"
  spec.require_paths = ["lib"]
  spec.add_dependency "connection_pool", "~>3.0"
  spec.add_dependency "zeitwerk", "~> 2.7"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata = {
    "homepage_uri" => "https://github.com/sergey-arkhipov/rails_soft_lock",
    "documentation_uri" => "https://github.com/sergey-arkhipov/rails_soft_lock/blob/master/README.md",
    "changelog_uri" => "https://github.com/sergey-arkhipov/rails_soft_lock/blob/main/CHANGELOG.md",
    "source_code_uri" => "https://github.com/sergey-arkhipov/rails_soft_lock",
    "bug_tracker_uri" => "https://github.com/sergey-arkhipov/rails_soft_lock/issues",
    "rubygems_mfa_required" => "true"
  }
end
