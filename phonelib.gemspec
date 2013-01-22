$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "phonelib/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "phonelib"
  s.version     = Phonelib::VERSION
  s.authors     = ["Vadim Senderovich"]
  s.email       = ["daddyzgm@gmail.com"]
  s.homepage    = "https://github.com/daddyz/phonelib"
  s.summary     = "Gem uses google libphonenumber database for validate phone numbers."
  s.description = "Google libphonenumber library was taken as a basis for this gem. It uses google data file for validations."

  s.files = Dir["{data,lib,tasks}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 3.1.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "nokogiri"
end
