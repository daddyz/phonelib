require 'phonelib'

RUNS = Integer(ENV['RUNS'] || 10)

def run_benchmark(test_numbers)
  start = Time.now
  100.times do
    test_numbers.each do |country, numbers|
      numbers.each do |number|
        Phonelib.parse(number, country)
      end
    end
  end
  eta = Time.now - start
  puts " => parsing rate = #{eta / 100.0} for cycle; #{eta} for 100 cycles"
end

puts "Timing phonelib using Ruby #{RUBY_VERSION}"

test_numbers = {}
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

puts "starting benchmark for #{test_numbers.values.map(&:size).inject(:+)} numbers in #{test_numbers.keys.size} countries"

RUNS.times do
  run_benchmark(test_numbers)
end
