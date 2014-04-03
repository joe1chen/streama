require "pry"
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "app/models")
SUPPORT = File.join(File.dirname(__FILE__), "support")
$LOAD_PATH.unshift(MODELS)
$LOAD_PATH.unshift(SUPPORT)

require 'streama'
require 'mongoid'
require 'rspec'
require 'database_cleaner'

LOGGER = Logger.new($stdout)

DatabaseCleaner.strategy = :truncation

def database_id
  ENV["CI"] ? "mongoid_#{Process.pid}" : "mongoid_test"
end

if Streama.mongoid2?
  Mongoid.configure do |config|
    database = Mongo::Connection.new.db(database_id)
    database.add_user("mongoid", "test")
    config.master = database
    config.logger = nil
  end
else
  Mongoid.configure do |config|
    config.connect_to(database_id)
  end
end

Dir[ File.join(MODELS, "*.rb") ].sort.each do |file|
  name = File.basename(file, ".rb")
  autoload name.camelize.to_sym, name
end
require File.join(MODELS,"mars","user.rb")

Dir[ File.join(SUPPORT, "*.rb") ].each do |file|
  require File.basename(file)
end

RSpec.configure do |config|
  config.include RSpec::Matchers
  config.include Mongoid::Matchers
  config.mock_with :rspec
  
  config.before(:each) do
    DatabaseCleaner.start
    Mongoid::IdentityMap.clear
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.after :suite do
    if Streama.mongoid2?
      Mongoid.master.connection.drop_database(database_id)
    else
      Mongoid.default_session.drop
    end
  end
  
end
