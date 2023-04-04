require 'benchmark_helper'

RUNS = Integer(ENV['RUNS'] || 10)

def run_benchmark(test_numbers)
  start = Time.now
  2.times do
    test_numbers.each do |country, numbers|
      numbers.each do |number|
        Phonelib.parse(number, country)
      end
    end
  end
  eta = Time.now - start
  puts " => parsing rate = #{eta / 100.0} for cycle; #{eta} for 100 cycles"
end

RUNS.times do
  run_benchmark(test_numbers)
end
