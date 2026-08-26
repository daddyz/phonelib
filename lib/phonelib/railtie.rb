# frozen_string_literal: true

module Phonelib
  class Railtie < Rails::Railtie
    initializer 'phonelib' do |app|
      app.config.eager_load_namespaces << Phonelib

      locale_files = Dir[File.expand_path('phonelib/locale/*.yml', __dir__)]
      app.config.i18n.load_path = locale_files | app.config.i18n.load_path if defined?(I18n)
    end
  end
end
