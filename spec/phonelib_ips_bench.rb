require 'benchmark_helper'

RSpec.describe Phonelib, :benchmark do
  it 'parsing numbers' do
    Benchmark.ips do |x|
      x.config(time: 5, warmup: 2)

      x.report('known country') do
        test_numbers.each do |country, numbers|
          numbers.each do |number|
            Phonelib.parse(number, country)
          end
        end
      end

      x.report('unknown country') do
        test_numbers.each do |country, numbers|
          numbers.each do |number|
            Phonelib.parse(number)
          end
        end
      end

      x.compare!
    end
  end
end
