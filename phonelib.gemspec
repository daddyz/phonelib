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

  s.post_install_message = <<-EOS
    IMPORTANT NOTICE!
    Phone types were changed from camel case to snake case!
    Example: ":tollFree" changed to ":toll_free".
    Please update your app in case your are checking types!
  EOS
  s.files = Dir['{data,lib,tasks}/**/*'] + %w(MIT-LICENSE Rakefile README.rdoc)
  s.test_files = Dir['test/**/*']

  s.add_development_dependency 'rails', '>= 3.1.0'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'shoulda-context', '= 1.1.2'
end
