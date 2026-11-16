# Loaded through .rspec before any spec file, so coverage starts before lib/ is required.
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/lib/phonelib/data_importer'
  add_filter '/lib/phonelib/errors.rb'
end
