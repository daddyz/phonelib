# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require 'shoulda-context'
require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
ActiveSupport::TestCase.fixture_path=(File.expand_path("../dummy/test/fixtures", __FILE__))

class ActiveSupport::TestCase
  fixtures :all
end
