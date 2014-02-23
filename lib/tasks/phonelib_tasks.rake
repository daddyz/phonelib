namespace :phonelib do

  desc 'Create database for tests in Rails dummy application'
  task :create_test_db do
    exit unless defined? Rails
    Rails.env = 'test'
    load 'spec/dummy/Rakefile'
    Rake::Task['db:setup'].invoke
  end

  desc 'Import and reparse original data file from Google libphonenumber'
  task :import_data do
    require 'net/http'
    require 'nokogiri'

    # get metadata from google
    url = 'http://libphonenumber.googlecode.com/svn/trunk/resources/PhoneNumberMetadata.xml'
    xml_data = Net::HTTP.get_response(URI.parse(url)).body
    xml_data.force_encoding("utf-8")

    # save in file for debug
    File.open('data/PhoneNumberMetaData.xml', 'w+') do |f|
      f.write(xml_data)
    end

    # start parsing
    doc = Nokogiri::XML(xml_data)

    main = doc.elements.first.elements.first
    countries = {}
    main.elements.each do |el|
      # each country
      country = {}
      el.attributes.each do |k, v|
        country[camel2snake(k).to_sym] = v.to_s.tr(" \n", '')
      end

      country[:types] = {}

      el.children.each do | phone_type |
        if !%w(comment text).include?(phone_type.name)
          phone_type_sym = camel2snake(phone_type.name).to_sym

          if phone_type.name != 'availableFormats'
            country[:types][phone_type_sym] = {}
            phone_type.elements.each do |pattern|
              country[:types][phone_type_sym][camel2snake(pattern.name).to_sym] =
                  pattern.children.first.to_s.tr(" \n", '')
            end
          else
            country[:formats] = []
            phone_type.children.each do |format|

              if !%w(comment text).include?(format.name)
                current_format = {}
                format.each do |f|
                  current_format[camel2snake(f[0]).to_sym] = f[1]
                end

                format.children.each do |f|
                  if f.name != 'text'
                    current_format[camel2snake(f.name).to_sym] =
                        f.children.first.to_s.gsub(/\n\s+/, '')
                  end
                end

                country[:formats].push(current_format)
              end
            end
          end

        end
      end

      countries[country[:id]] = country
    end
    File.open('data/phone_data.dat', 'wb+') do |f|
      Marshal.dump(countries, f)
    end
  end

  def camel2snake(s)
    s.gsub(/[A-Z]+/) { |m| "_#{m.downcase}" }
  end
end
