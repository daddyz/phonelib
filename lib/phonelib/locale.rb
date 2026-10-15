# frozen_string_literal: true

require 'yaml'

module Phonelib
  module Locale
    FILES = Dir[File.expand_path('locale/*.yml', __dir__)].freeze

    def self.register
      # Look up application translations before registering the default files:
      # the lookup initializes a lazy backend using its existing load path.
      FILES.each do |file|
        YAML.load_file(file).each do |locale, data|
          data['errors']['messages'].each do |key, message|
            unless I18n.backend.exists?(locale, key, scope: [:errors, :messages])
              I18n.backend.store_translations(locale, errors: { messages: { key => message } })
            end
          end
        end
      end

      # Future reloads load gem defaults before application overrides, without
      # reloading the current backend or discarding its stored translations.
      I18n.load_path.replace(FILES | I18n.load_path)
    end
  end
end
