require 'phonelib'

RUNS = Integer(ENV['RUNS'] || 10)
TEST_NUMBER = ENV['TEST_NUMBER'] || '+18555000000'

def run_benchmark
  start = Time.now
  100.times do
    Phonelib.valid?(TEST_NUMBER)
  end
  puts "valid? rate: #{100/(Time.now-start)} calls/s"
end

puts "Timing phonelib using Ruby #{RUBY_VERSION}"

RUNS.times do
  run_benchmark
end
