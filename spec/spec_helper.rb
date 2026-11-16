# Loaded through .rspec before any spec file, so coverage starts before lib/ is required.
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end
