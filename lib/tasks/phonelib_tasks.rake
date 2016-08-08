namespace :phonelib do
  desc 'Create database for tests in Rails dummy application'
  task :create_test_db do
    exit unless defined? Rails
    Rails.env = 'test'
    load 'spec/dummy/Rakefile'
    Rake::Task['db:setup'].invoke
  end

  desc 'Import and reparse original data file from Google libphonenumber'
  task :import_data do
    require 'phonelib/data_importer'
    Phonelib::DataImporter.import
  end
end
