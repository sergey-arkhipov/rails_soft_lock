# frozen_string_literal: true

require_relative "lib/rails_soft_lock/version"

Gem::Specification.new do |spec|
  spec.name = "rails_soft_lock"
  spec.version = RailsSoftLock::VERSION
  spec.authors = ["Sergey Arkhipov", "Vladimir Peskov"]
  spec.email = ["Sergey-Arkhipov@yandex.ru", "vpeskov@niomed.ru"]

  spec.summary = "Lock Active record by attribyte using in-memory adapters"
  spec.description = "Using In-Memory Databases to Work with Rails Active Record Locks"
  spec.homepage = "https://github.com/sergey-arkhipov/rails_soft_lock"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = ""

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sergey-arkhipov/rails_soft_lock"
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

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
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "connection_pool", "~>2.5"
  spec.add_dependency "zeitwerk", "~> 2.7"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
