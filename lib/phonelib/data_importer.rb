module Phonelib
  # module processes creation of data files needed for this gem
  module DataImporter
    require 'nokogiri'

    # official libphonenumber repo for cloning
    REPO = 'https://github.com/googlei18n/libphonenumber.git'

    # importing function
    def self.import
      Importer.new
    end

    # class with functionality for importing data
    class Importer
      # main data file in repo
      MAIN_FILE = 'resources/PhoneNumberMetadata.xml'
      # short number metadata
      SHORT_DATA_FILE = 'resources/ShortNumberMetadata.xml'
      # alternate formats data file in repo
      FORMATS_FILE = 'resources/PhoneNumberAlternateFormats.xml'
      # geocoding data dir in repo
      GEOCODING_DIR = 'resources/geocoding/en/'
      # carrier data dir in repo
      CARRIER_DIR = 'resources/carrier/en/'
      # timezones data dir in repo
      TIMEZONES_DIR= 'resources/timezones/'

      # xml comments attributes names that should not be parsed
      XML_COMMENT_ATTRIBUTES = %w(text comment)
      # xml format attributes names
      XML_FORMAT_NAMES = %w(intlFormat format)

      # class initialization method
      def initialize
        @destination = File.path(
            "#{File.dirname(__FILE__)}/../../data/libphonenumber/")
        @data = {}
        @prefixes = {}
        @geo_names = []
        @timezones = []
        @carriers = []

        clone_repo
        import_main_data
        import_short_data
        import_alternate_formats
        import_geocoding_data
        import_timezone_data
        import_carrier_data
        save_data_file
      end

      private

      # method saves parsed data to data files
      def save_data_file
        data_file =
            "#{File.dirname(__FILE__)}/../../#{Phonelib::Core::FILE_MAIN_DATA}"

        File.open(data_file, 'wb+') do |f|
          Marshal.dump(@data, f)
        end

        ext_file =
            "#{File.dirname(__FILE__)}/../../#{Phonelib::Core::FILE_EXT_DATA}"
        extended = {
          Phonelib::Core::EXT_PREFIXES => @prefixes,
          Phonelib::Core::EXT_GEO_NAMES => @geo_names,
          Phonelib::Core::EXT_TIMEZONES => @timezones,
          Phonelib::Core::EXT_CARRIERS => @carriers
        }
        File.open(ext_file, 'wb+') do |f|
          Marshal.dump(extended, f)
        end
        puts 'DATA SAVED'
      end

      # method clones libphonenumber repo to local dir
      def clone_repo
        repo = Phonelib::DataImporter::REPO

        system("rm -rf #{@destination}")
        cloned = system("git clone #{repo} #{@destination} --depth 1 -b master")
        raise 'Could not clone repo' unless cloned
      end

      # method parses main data file
      def import_main_data
        puts 'IMPORTING MAIN DATA'
        main_from_xml("#{@destination}#{MAIN_FILE}").elements.each do |el|
          # each country
          country = get_hash_from_xml(el, :attributes)
          country[:types] = {}

          without_comments(el.children).each do | phone_type |
            if phone_type.name == 'availableFormats'
              country[:formats] = parse_formats(phone_type.children)
            else
              country[:types][name2sym(phone_type.name)] =
                  get_hash_from_xml(phone_type, :element)
            end
          end

          country[:types] = add_possible_if_not_exists(country[:types])

          @data[country[:id]] = country
        end
      end

      # method parses main data file
      def import_short_data
        puts 'IMPORTING SHORT NUMBER DATA'
        main_from_xml("#{@destination}#{SHORT_DATA_FILE}").elements.each do |el|
          # each country
          country = get_hash_from_xml(el, :attributes)
          country[:types] = {}

          without_comments(el.children).each do | phone_type |
            country[:types][name2sym(phone_type.name)] =
                get_hash_from_xml(phone_type, :element)
          end

          country[:types] = add_possible_if_not_exists(country[:types])

          id = country[:id]
          country[:types].each do |type, data|
            @data[id][:types][type] = data && next unless @data[id][:types][type]

            data.each do |k, v|
              if @data[id][:types][type][k]
                @data[id][:types][type][k] += "|#{v}"
              else
                @data[id][:types][type][k] = v
              end
            end
          end
        end
      end

      # method parses alternate formats file
      def import_alternate_formats
        puts 'IMPORTING ALTERNATE FORMATS'


        main_from_xml("#{@destination}#{FORMATS_FILE}").elements.each do |el|
          el.children.each do | phone_type |
            if phone_type.name == 'availableFormats'
              formats = parse_formats(phone_type.children)

              country_code = el.attribute('countryCode').value
              @data[get_country_by_code(country_code)][:formats] += formats
            end
          end
        end
      end

      # method parses geocoding data dir
      def import_geocoding_data
        puts 'IMPORTING GEOCODING DATA'
        import_raw_files_data("#{@destination}#{GEOCODING_DIR}*",
                              @geo_names,
                              :g)
      end

      # method parses timezones data dir
      def import_timezone_data
        puts 'IMPORTING TIMEZONES DATA'
        import_raw_files_data("#{@destination}#{TIMEZONES_DIR}*",
                              @timezones,
                              :t)
      end

      # method parses carriers data dir
      def import_carrier_data
        puts 'IMPORTING CARRIER DATA'
        import_raw_files_data("#{@destination}#{CARRIER_DIR}*",
                              @carriers,
                              :c)
      end

      # adds possible pattern in case it doesn't exists
      def add_possible_if_not_exists(types)
        types.each do |type, data|
          if data[Core::VALID_PATTERN] && !data[Core::POSSIBLE_PATTERN]
            types[type][Core::POSSIBLE_PATTERN] =
                data[Core::VALID_PATTERN]
          end
        end
        types
      end

      # method filters xml elements excluding comments elements
      def without_comments(data)
        data.select do |el|
          !XML_COMMENT_ATTRIBUTES.include? el.name
        end
      end

      # method creates hash from xml elements/element attributes
      def get_hash_from_xml(data, type)
        hash = {}
        case type
          when :attributes
            data.attributes.each do |k, v|
              hash[name2sym(k)] = str_clean(v)
            end
          when :children
            data.each do |f|
              hash[name2sym(f[0])] = f[1]
            end
          when :element
            data.elements.each do |child|
              hash[name2sym(child.name)] = str_clean(child.children.first)
            end
        end
        hash
      end

      # method parses xml for formats data
      def parse_formats(formats_children)
        without_comments(formats_children).map do |format|
          current_format = get_hash_from_xml(format, :children)

          without_comments(format.children).each do |f|
            current_format[name2sym(f.name)] =
                str_clean(f.children.first, is_not_format(f.name))
          end

          current_format
        end.compact
      end

      # method updates data from raw files
      def import_raw_files_data(dir, var, key)
        name2index = {}
        Dir["#{dir}"].each do |file|
          parse_raw_file(file).each do |prefix, name|
            unless name2index[name]
              var.push name
              name2index[name] = var.size - 1
            end

            @prefixes = fill_prefixes(key, name2index[name], prefix, @prefixes)
          end
        end
      end

      # method updates prefixes hash recursively
      def fill_prefixes(key, value, prefix, prefixes)
        prefixes = {} if prefixes.nil?
        if prefix.size == 1
          prefixes[prefix.to_i] = {} unless prefixes[prefix.to_i]
          prefixes[prefix.to_i][key] = value
        else
          pr = prefix[0].to_i
          prefixes[pr] = fill_prefixes(key, value, prefix[1..-1], prefixes[pr])
        end
        prefixes
      end

      # method parses raw data file
      def parse_raw_file(file)
        data = {}
        File.readlines(file).each do |line|
          line = str_clean line
          next if line.empty? || line[0] == '#'
          prefix, line_data = line.split('|')
          data[prefix] = line_data && line_data.split('&')
        end
        data
      end

      # method for checking if element name is not a format element
      def is_not_format(name)
        !XML_FORMAT_NAMES.include? name
      end

      # get main body from parsed xml document
      def main_from_xml(file)
        xml_data = File.read(file)
        xml_data.force_encoding("utf-8")

        doc = Nokogiri::XML(xml_data)
        doc.elements.first.elements.first
      end

      # method finds country by country prefix
      def get_country_by_code(country_code)
        match = @data.select { |k, v| v[:country_code] == country_code }
        if match.size > 1
          match = match.select { |k, v| v[:main_country_for_code] == 'true' }
        end

        match.keys.first
      end

      # helper that cleans string
      def str_clean(s, white_space = true)
        s.to_s.tr(white_space ? " \n" : "\n", '')
      end

      # helper that converts xml element name to symbol
      def name2sym(name)
        camel2snake(name).to_sym
      end

      # method that converts camel case to snake case
      def camel2snake(s)
        s.gsub(/[A-Z]+/) { |m| "_#{m.downcase}" }
      end
    end
  end
end