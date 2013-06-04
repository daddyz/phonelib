$:.push File.expand_path("../lib", __FILE__)
require "phonelib/version"

Gem::Specification.new do |s|
  s.name        = "phonelib"
  s.version     = Phonelib::VERSION
  s.authors     = ["Vadim Senderovich"]
  s.email       = ["daddyzgm@gmail.com"]
  s.homepage    = "https://github.com/daddyz/phonelib"
  s.summary     = "Gem validates phone numbers with Google libphonenumber database."
  s.description = "Google libphonenumber library was taken as a basis for this gem."\
      " Gem uses its data file for validations and number formatting."

  s.files = Dir["{data,lib,tasks}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_development_dependency "rails", ">= 3.1.0"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "nokogiri"
  s.add_development_dependency "pry"
  s.add_development_dependency 'shoulda-context'
end
