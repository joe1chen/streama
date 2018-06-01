# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "streama/version"

Gem::Specification.new do |s|
  s.name        = "streama"
  s.version     = Streama::VERSION
  s.authors     = ["Christos Pappas"]
  s.email       = ["christos.pappas@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Activity Streams for Mongoid}
  s.description = %q{Streama is a simple activity stream gem for use with the Mongoid ODM framework}

  s.rubyforge_project = "streama"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "mongoid"
  s.add_runtime_dependency "mongoid-compatibility"

  s.add_development_dependency "rspec"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "pry"
  s.add_development_dependency "rake"
end
