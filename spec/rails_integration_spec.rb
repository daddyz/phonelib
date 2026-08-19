# frozen_string_literal: true

require 'open3'
require 'rbconfig'

describe 'Rails integration' do
  def unbundled_environment
    environment = {
      'RUBYLIB' => nil,
      'RUBYOPT' => nil,
      'RUBYGEMS_GEMDEPS' => nil
    }
    ENV.each_key do |name|
      environment[name] = nil if name.start_with?('BUNDLE_')
    end
    environment
  end

  def run_phonelib_script(program)
    lib_path = File.expand_path('../lib', File.dirname(__FILE__))

    Open3.capture3(
      unbundled_environment,
      RbConfig.ruby,
      '--disable-gems',
      "-I#{lib_path}",
      '-e',
      program
    )
  end

  def expect_phonelib_script_to_succeed(program)
    _stdout, stderr, status = run_phonelib_script(program)

    expect(status.success?).to eq(true), stderr
  end

  it 'loads when Rails is defined before Rails::Railtie is available' do
    program = <<-RUBY
      module Rails
      end

      require 'phonelib'

      abort 'Phonelib loaded optional Rails components' if defined?(Rails::Railtie)
    RUBY

    expect_phonelib_script_to_succeed(program)
  end

  it 'registers eager loading when Rails::Railtie is available' do
    program = <<-RUBY
      module Rails
        class Railtie
          class << self
            attr_reader :initializer_name, :initializer_block

            def initializer(name, &block)
              @initializer_name = name
              @initializer_block = block
            end
          end
        end
      end

      require 'phonelib'

      abort 'Phonelib::Railtie was not registered' unless Phonelib::Railtie < Rails::Railtie
      abort 'Phonelib initializer was not registered' unless Phonelib::Railtie.initializer_name == 'phonelib'

      config = Struct.new(:eager_load_namespaces).new([])
      app = Struct.new(:config).new(config)
      Phonelib::Railtie.initializer_block.call(app)

      abort 'Phonelib was not added to eager load namespaces' unless config.eager_load_namespaces == [Phonelib]
    RUBY

    expect_phonelib_script_to_succeed(program)
  end
end
