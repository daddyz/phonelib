require 'benchmark_helper'

RSpec.describe Phonelib, :benchmark do
  before do
    Phonelib.parse(test_numbers.each_value.first)
  end

  it 'parsing numbers' do
    Benchmark.memory do |x|
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
