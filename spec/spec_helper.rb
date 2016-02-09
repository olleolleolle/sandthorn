# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
require 'coveralls'
Coveralls.wear!
require "ap"
require "bundler"
require "sandthorn_driver_sequel"
require "support/custom_matchers"

Bundler.require

module Helpers
  def class_including(mod)
    Class.new.tap {|c| c.send :include, mod }
  end
end

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.filter_run_excluding benchmark: true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
  config.before(:each) { sqlite_store_setup }

  config.after(:each) do
    Sandthorn.event_stores.default_store.driver.instance_variable_get(:@db).disconnect
  end
end

def spec_db
  "sqlite://spec/db/sequel_driver.sqlite3"
end
def sqlite_store_setup
  url = spec_db

  driver = SandthornDriverSequel.driver_from_url(url: url) do |conf|
    conf.event_serializer       = Proc.new { |data| YAML::dump(data) }
    conf.event_deserializer     = Proc.new { |data| YAML::load(data) }
    conf.snapshot_serializer    = Proc.new { |data| YAML::dump(data) }
    conf.snapshot_deserializer  = Proc.new { |data| YAML::load(data) }
  end

  Sandthorn.configure do |c|
    c.event_store = driver
    #c.snapshot_serializer = Proc.new { |data| YAML::dump(data) }
    #c.snapshot_deserializer = Proc.new { |data| YAML::load(data) }
  end
  migrator = SandthornDriverSequel::Migration.new url: url
  SandthornDriverSequel.migrate_db url: url
  migrator.send(:clear_for_test)
end
