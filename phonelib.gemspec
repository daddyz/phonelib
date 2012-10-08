$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "phonelib/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "phonelib"
  s.version     = Phonelib::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Phonelib."
  s.description = "TODO: Description of Phonelib."

  s.files = Dir["{app,config,db,lib,tasks}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.8"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "nokogiri"
end
