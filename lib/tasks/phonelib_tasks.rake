namespace :phonelib do

  desc "Explaining what the task does"
  task :import_data do
    require 'net/http'
    require 'yaml'
    require 'nokogiri'

    #url = 'http://libphonenumber.googlecode.com/svn/trunk/resources/PhoneNumberMetaData.xml'
    
    #xml_data = Net::HTTP.get_response(URI.parse(url)).body
    xml_data = File.read('PhoneNumberMetaData.xml')
    doc = Nokogiri::XML(xml_data)
#REXML::Document.new(xml_data)

    require 'pp'
    main = doc.elements.first.elements.first
    countries = []
    main.elements.each do |el|
      # each country
      country = {}
      el.attributes.each do |k, v| 
        #puts k + " " + v
        country[k.to_sym] = v.to_s 
      end

      country[:types] = {}

      el.children.each do | phone_type | 
        if phone_type.name != 'comment' && phone_type.name != 'text'
          phone_type_sym = phone_type.name.to_sym  
           
          if phone_type.name != 'availableFormats'
            country[:types][phone_type_sym] = {}
            #puts "  " + phone_type.name 
            phone_type.elements.each do |pattern| 
              #puts "    " + pattern.name + " = " + pattern.children.first.to_s.tr(" \n", "")
              country[:types][phone_type_sym][pattern.name.to_sym] = pattern.children.first.to_s.tr(" \n", "")
            end
          else
            country[:formats] = []
            #puts "  " + phone_type.name
            phone_type.children.each do |format|
              
              if format.name != 'text' && format.name != 'comment'
                current_format = { regex: format.first[1].to_s.tr(" \n", "") }

                #puts "    " + format.name + " = " + format.first[1]
                format.children.each do |f|
                  if f.name != 'text'
                    
                    current_format[f.name.to_sym] = f.children.first.to_s.tr(" \n", "")
                    #puts "      " + f.name + " = " + f.children.first

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
    pp countries
    target = 'data/phone_data.yml'
    File.open(target, "w+") do |f|
      f.write(countries.to_yaml)
    end
    
    #main.children.each do | c |
    #  pp c
    #end
    #doc.elements.each do | el |
    #  pp el
    #  exit
    #end
  end
end  