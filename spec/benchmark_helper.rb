# frozen_string_literal: true

ENV["RAILS_ENV"] ||= 'test'

require 'benchmark/ips'
require 'benchmark/memory'
require 'benchmark'
require 'phonelib'
require 'rspec'

puts "Timing phonelib using Ruby #{RUBY_VERSION}"

def test_numbers
  @test_numbers ||= {}.tap do |test_numbers|
    data_file = File.dirname(__FILE__) + '/../data/phone_data.dat'
    phone_data = Marshal.load(File.binread(data_file))
    phone_data.each do |key, data|
      country = data[:id]
      next unless country =~ /[A-Z]{2}/
      data[:types].each do |type, type_data|
        next unless Phonelib::Core::TYPES_DESC.keys.include? type
        next unless type_data[:example_number]
        type_data[:example_number].split('|').each do |number|
          test_numbers[key] ||= []
          test_numbers[key] << number
        end
      end
    end
  end
end

puts "starting benchmark for #{test_numbers.values.map(&:size).inject(:+)} numbers in #{test_numbers.keys.size} countries"
