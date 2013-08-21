namespace :phonelib do

  desc "Import and reparse original data file from Google libphonenumber"
  task :import_data do
    require 'net/http'
    require 'yaml'
    require 'nokogiri'

    # get metadata from google
    url = 'http://libphonenumber.googlecode.com/svn/trunk/resources/PhoneNumberMetadata.xml'
    xml_data = Net::HTTP.get_response(URI.parse(url)).body

    # save in file for debug
    File.open("data/PhoneNumberMetaData.xml", "w+") do |f|
      f.write(xml_data)
    end

    # start parsing
    doc = Nokogiri::XML(xml_data)

    main = doc.elements.first.elements.first
    countries = []
    main.elements.each do |el|
      # each country
      country = {}
      el.attributes.each do |k, v|
        country[k.to_sym] = v.to_s.tr(" \n", "")
      end

      country[:types] = {}

      el.children.each do | phone_type |
        if !%w(comment text).include?(phone_type.name)
          phone_type_sym = phone_type.name.to_sym

          if phone_type.name != 'availableFormats'
            country[:types][phone_type_sym] = {}
            phone_type.elements.each do |pattern|
              country[:types][phone_type_sym][pattern.name.to_sym] =
                  pattern.children.first.to_s.tr(" \n", "")
            end
          else
            country[:formats] = []
            phone_type.children.each do |format|

              if !%w(comment text).include?(format.name)
                current_format = {}
                format.each do |f|
                  current_format[f[0].to_sym] = f[1]
                end

                format.children.each do |f|
                  if f.name != 'text'
                    current_format[f.name.to_sym] = f.children.first.to_s.tr(" \n", "")
                  end
                end

                country[:formats].push(current_format)
              end
            end
          end

        end
      end

      countries.push(country)
    end
    target = 'data/phone_data.yml'
    File.open(target, "w+") do |f|
      f.write(countries.to_yaml)
    end
  end
end
