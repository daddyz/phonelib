source "http://rubygems.org"

gem "rails", "~> 6.1.1"
gem 'rspec-rails', '4.0.2'
gem 'rspec', '3.10.0'
gem "sqlite3", '~> 1.4.2'
gem "mime-types", "~> 3.3.1"
gem 'rails-controller-testing'
if RUBY_VERSION < '2.3.0'
  gem 'nokogiri', '~> 1.8.2'
elsif RUBY_VERSION > '3.0.0'
  gem 'nokogiri', '~> 1.16'
elsif RUBY_VERSION > '2.7.0'
  gem 'nokogiri', '~> 1.15'
else
  gem 'nokogiri', '~> 1.10'
end
gemspec :path=>"../"

gem 'rake', '< 14.0'

gem 'simplecov'
gem 'benchmark-ips'
gem 'benchmark-memory'

# fixing CI tests
gem 'rack-cache', '= 1.2'
gem 'json', '= 2.3.1'
gem 'concurrent-ruby', '1.3.4'