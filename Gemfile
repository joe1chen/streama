source "http://rubygems.org"

# Specify your gem's dependencies in streama.gemspec
gemspec

case version = ENV['MONGOID_VERSION'] || "~> 3.1"
  when /4/
    gem "mongoid", :github => 'mongoid/mongoid'
  when /3/
    gem "mongoid", "~> 3.1"
  when /2/
    gem "mongoid", "~> 2.8"
  else
    gem "mongoid", version
end