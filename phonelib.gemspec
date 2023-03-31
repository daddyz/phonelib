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
  s.rdoc_options << ' --no-private - CHANGELOG.md --readme README.md'
  s.files = Dir['{lib,tasks}/**/*'] + Dir['data/*.dat'] + %w(MIT-LICENSE Rakefile README.md)
  s.test_files = Dir['test/**/*']

  s.add_development_dependency 'rake', '< 14.0'
  if RUBY_VERSION < '2.3.0'
    s.add_development_dependency 'nokogiri', '~> 1.8.2'
  elsif RUBY_VERSION > '2.6.0'
    s.add_development_dependency 'nokogiri', '~> 1.13.0'
  else
    s.add_development_dependency 'nokogiri', '~> 1.10.10'
  end
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec', '= 2.14.1'
  s.add_development_dependency 'codeclimate-test-reporter', '~> 1.0.0'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'benchmark-ips'
  s.add_development_dependency 'benchmark-memory'
  # fixing CI tests
  s.add_development_dependency 'rack-cache', '= 1.2'
  s.add_development_dependency 'json', '= 2.3.1'
end
