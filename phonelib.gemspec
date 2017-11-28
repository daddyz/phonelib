$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'phonelib/version'

Gem::Specification.new do |s|
  s.name = 'phonelib'
  s.version = Phonelib::VERSION
  s.authors = ['Vadim Senderovich']
  s.email = ['daddyzgm@gmail.com']
  s.homepage = 'https://github.com/daddyz/phonelib'
  s.summary = 'Gem validates phone numbers with Google libphonenumber database'
  s.description = <<-EOS
    Google libphonenumber library was taken as a basis for
    this gem. Gem uses its data file for validations and number formatting.
  EOS
  s.license = 'MIT'
  s.has_rdoc = 'yard'
  s.rdoc_options << ' --no-private - CHANGELOG.md --readme README.md'
  s.files = Dir['{lib,tasks}/**/*'] + Dir['data/*.dat'] + %w(MIT-LICENSE Rakefile README.md)
  s.test_files = Dir['test/**/*']

  s.add_development_dependency 'rake', '< 11.0'
  s.add_development_dependency 'nokogiri', '= 1.6.0'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec', '= 2.14.1'
  s.add_development_dependency 'codeclimate-test-reporter', '~> 1.0.0'
  s.add_development_dependency 'simplecov'
  # fixing CI tests
  s.add_development_dependency 'rack-cache', '= 1.2'
  s.add_development_dependency 'rack', '= 1.6.2'
  s.add_development_dependency 'json', '= 1.8.6'
end
