ENV["RAILS_ENV"] ||= 'test'

require File.absolute_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'active_support'
require 'yaml'

# fixtures method definition
FIXTURES = Dir[File.absolute_path('../fixtures/*.yml', __FILE__)].map do |f|
  File.basename(f)
end

def method_missing(method, *args)
  if FIXTURES.include? "#{method}.yml"
    file = File.absolute_path("../fixtures/#{method}.yml", __FILE__)
    klass = method.to_s.singularize.capitalize.constantize
    fixtures = HashWithIndifferentAccess.new(YAML.load_file(file))
    klass.new(fixtures[args[0]])
  else
    super
  end
end

# assert_difference method definition
def assert_difference(klass, method, change = nil, &block)
  before = klass.send(method)
  block.call
  after = klass.send(method)
  if change
    expect(after).to eq(before + change)
  else
    expect(after).not_to eq(before)
  end
end