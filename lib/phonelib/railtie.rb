# frozen_string_literal: true

module Phonelib
  class Railtie < Rails::Railtie
    initializer 'phonelib' do |app|
      app.config.eager_load_namespaces << Phonelib
    end
  end
end
