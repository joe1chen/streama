module Streama
  def self.mongoid2?
    ::Mongoid.const_defined? :Contexts
  end
  def self.mongoid3?
    ::Mongoid.const_defined? :Observer
  end
end

require "mongoid"
require "streama/version"
require "streama/actor"
require "streama/activity"
require "streama/definition"
require "streama/definition_dsl"
require "streama/errors"