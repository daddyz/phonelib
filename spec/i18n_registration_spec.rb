require 'open3'
require 'rbconfig'

_output, _error, i18n_available = Open3.capture3(RbConfig.ruby, '-e', "require 'i18n'; require 'active_model'")

if i18n_available.success?
  describe 'Non-destructive I18n registration' do
    [:require, :validator].each do |entry|
      [false, true].each do |initialized|
        it "preserves stored translations and file overrides via #{entry} (initialized: #{initialized})" do
          script = <<-RUBY
            #{"require 'phonelib'; require 'active_model'" if entry == :validator}
            require 'i18n'
            require 'tempfile'

            locale = Tempfile.new(['phonelib-application', '.yml'])
            locale.write("en:\n  errors:\n    messages:\n      phone_too_short: application override\n")
            locale.close
            I18n.load_path = [locale.path]
            I18n.backend.store_translations(:en,
              registration_greeting: 'hello',
              errors: { messages: { phone_invalid: 'stored override' } }
            )
            #{"I18n.t(:registration_greeting)" if initialized}
            backend = I18n.backend
            abort 'wrong initial state' unless backend.initialized? == #{initialized}

            #{entry == :require ? "require 'phonelib'" : 'PhoneValidator'}

            abort 'backend replaced' unless I18n.backend.equal?(backend)
            abort 'stored translation lost' unless I18n.t(:registration_greeting) == 'hello'
            abort 'stored override lost' unless I18n.t('errors.messages.phone_invalid') == 'stored override'
            abort 'file override lost' unless I18n.t('errors.messages.phone_too_short') == 'application override'
            abort 'new default missing' unless I18n.t('errors.messages.phone_too_long') == 'is too long'

            I18n.reload!
            abort 'file override lost after reload' unless I18n.t('errors.messages.phone_too_short') == 'application override'
            abort 'default missing after reload' unless I18n.t('errors.messages.phone_too_long') == 'is too long'
          RUBY

          _output, error, status = Open3.capture3(RbConfig.ruby, '-Ilib', '-e', script)
          expect(status.success?).to eq(true), error
        end
      end
    end

    _output, _error, rails_available = Open3.capture3(RbConfig.ruby, '-e', "require 'rails'; require 'active_model/railtie'")

    if rails_available.success?
      it 'preserves application file and runtime overrides in an initialized Rails application' do
        script = <<-RUBY
          ENV['RAILS_ENV'] = 'test'
          require 'rails'
          require 'rails/application'
          require 'active_model/railtie'
          require 'tmpdir'
          require 'phonelib'

          Dir.mktmpdir('phonelib-registration') do |root|
            locale = File.join(root, 'application.yml')
            File.write(locale, "en:\n  errors:\n    messages:\n      phone_too_short: application override\n")
            class RegistrationApplication < Rails::Application
            end
            app = RegistrationApplication.instance
            app.config.root = root
            app.config.eager_load = false
            app.config.secret_key_base = 'synthetic-registration-test-secret-key-base'
            app.config.logger = Logger.new(IO::NULL)
            app.config.i18n.load_path << locale
            app.initialize!
            abort 'file override missing at boot' unless I18n.t('errors.messages.phone_too_short') == 'application override'
            abort 'default missing at boot' unless I18n.t('errors.messages.phone_invalid') == 'is not a valid phone number'
            I18n.backend.store_translations(:en,
              registration_greeting: 'hello',
              errors: { messages: { phone_too_long: 'runtime override' } }
            )
            I18n.t(:registration_greeting)

            class RailsRegistrationContact
              include ActiveModel::Model
              attr_accessor :phone
              validates :phone, phone: { detailed_errors: true }
            end
            contact = RailsRegistrationContact.new(phone: '+1 253000')
            abort 'fixture unexpectedly valid' if contact.valid?
            abort 'stored translation lost' unless I18n.t(:registration_greeting) == 'hello'
            abort 'stored override lost' unless I18n.t('errors.messages.phone_too_long') == 'runtime override'
            abort 'file override lost' unless contact.errors.messages[:phone] == ['application override']

            I18n.reload!
            abort 'override missing after reload' unless I18n.t('errors.messages.phone_too_short') == 'application override'
            abort 'default missing after reload' unless I18n.t('errors.messages.phone_invalid') == 'is not a valid phone number'
          end
        RUBY
        _output, error, status = Open3.capture3(RbConfig.ruby, '-Ilib', '-e', script)
        expect(status.success?).to eq(true), error
      end
    end

    it 'preserves runtime overrides when the validator loads after core registration' do
      script = <<-RUBY
        require 'i18n'
        require 'active_model'
        require 'phonelib'
        I18n.backend.store_translations(:en,
          registration_greeting: 'hello',
          errors: { messages: { phone_too_short: 'runtime override' } }
        )
        I18n.t(:registration_greeting)

        class RegistrationContact
          include ActiveModel::Model
          attr_accessor :phone
          validates :phone, phone: { detailed_errors: true }
        end
        contact = RegistrationContact.new(phone: '+1 253000')
        abort 'expected invalid fixture' if contact.valid?
        abort 'runtime translation lost' unless I18n.t(:registration_greeting) == 'hello'
        abort 'runtime error override lost' unless contact.errors.messages[:phone] == ['runtime override']
        abort 'default missing' unless I18n.t('errors.messages.phone_too_long') == 'is too long'
      RUBY
      _output, error, status = Open3.capture3(RbConfig.ruby, '-Ilib', '-e', script)
      expect(status.success?).to eq(true), error
    end
  end
end
