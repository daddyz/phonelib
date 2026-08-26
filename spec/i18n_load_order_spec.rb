require 'open3'
require 'rbconfig'

_output, _error, i18n_available = Open3.capture3(
  RbConfig.ruby,
  '-e',
  "require 'i18n'"
)

if i18n_available.success?
  describe 'I18n locale loading' do
    def translated_message(script)
      output, error, status = Open3.capture3(RbConfig.ruby, '-Ilib', '-e', script)

      expect(status.exitstatus).to eq(0), error
      output
    end

    it 'lets an application override detailed errors when Phonelib loads after I18n' do
      script = <<-RUBY
        require 'i18n'
        require 'tempfile'

        locale = Tempfile.new(['phonelib-application', '.yml'])
        locale.write("en:\n  errors:\n    messages:\n      phone_too_short: application override\n")
        locale.close
        I18n.load_path = [locale.path]

        require 'phonelib'
        puts I18n.t('errors.messages.phone_too_short')
      RUBY

      expect(translated_message(script)).to eq("application override\n")
    end

    it 'lets an application override detailed errors when the validator loads I18n' do
      script = <<-RUBY
        require 'phonelib'
        require 'i18n'
        require 'active_model'
        require 'tempfile'

        locale = Tempfile.new(['phonelib-application', '.yml'])
        locale.write("en:\n  errors:\n    messages:\n      phone_too_short: application override\n")
        locale.close
        I18n.load_path = [locale.path]

        PhoneValidator
        puts I18n.t('errors.messages.phone_too_short')
      RUBY

      expect(translated_message(script)).to eq("application override\n")
    end
  end
end
