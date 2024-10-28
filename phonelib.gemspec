# frozen_string_literal: true

require_relative 'lib/phonelib/version'

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

  s.metadata = {
    'changelog_uri' => "#{s.homepage}/releases/tag/v#{s.version}"
  }
end
