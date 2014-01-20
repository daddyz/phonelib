begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end
Bundler.require

begin
  # can't do anything to make build pass on ruby 1.9.2
  require 'rdoc/task'
  RDoc::Task.new(:rdoc) do |rdoc|
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title    = 'Phonelib'
    rdoc.options << '--line-numbers'
    rdoc.rdoc_files.include('README.rdoc')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
rescue
  puts 'Running without rdoc tasks'
end

Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  if defined? Rails
    puts 'Rails found! Running tests with Rails'
    t.pattern = 'spec/**/*_spec.rb'
  else
    puts 'Rails not found! Running tests without Rails'
    t.pattern = 'spec/*_spec.rb'
  end
end
task :default => :spec

load 'tasks/phonelib_tasks.rake'
