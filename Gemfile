source "http://rubygems.org"

gemspec

gem 'pry'
gem 'rake', '< 14.0'

if RUBY_VERSION < '2.3.0'
  gem 'nokogiri', '~> 1.8.2'
elsif RUBY_VERSION > '2.6.0'
  gem 'nokogiri', '~> 1.15'
elsif RUBY_VERSION > '3.0.0'
  gem 'nokogiri', '~> 1.16'
else
  gem 'nokogiri', '~> 1.10'
end

if RUBY_VERSION > '3.1.0'
  gem 'rspec'
else
  gem 'rspec', '= 2.14.1'
end

gem 'codeclimate-test-reporter', '~> 1.0.9'
gem 'simplecov'
gem 'benchmark-ips'
gem 'benchmark-memory'

# fixing CI tests
gem 'rack-cache', '= 1.2'
gem 'json', '= 2.3.1'
