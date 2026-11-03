# frozen_string_literal: true

module Phonelib
  class Railtie < Rails::Railtie
    initializer 'phonelib' do |app|
      app.config.eager_load_namespaces << Phonelib

      app.config.i18n.load_path = Phonelib::Locale::FILES | app.config.i18n.load_path if defined?(I18n)
    end
  end
end
