require 'phonelib/data_importer_helper'

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
      include Phonelib::DataImporterHelper

      # countries that can have double country prefix in number
      DOUBLE_COUNTRY_CODES_COUNTRIES = %w(IN DE BR)

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

          country.merge! get_types_and_formats(el.children)
          country = add_double_country_flag country
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

          country.merge! get_types_and_formats(el.children)

          country[:types].each do |type, data|
            if @data[country[:id]][:types][type]
              merge_short_with_main_type(country[:id], type, data)
            else
              @data[country[:id]][:types][type] = data
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

      # adds double country code flag in case country allows
      def add_double_country_flag(country)
        if DOUBLE_COUNTRY_CODES_COUNTRIES.include?(country[:id])
          country[:double_prefix] = true
        end
        country
      end

      # method extracts formats and types from xml data
      def get_types_and_formats(children)
        types = {}
        formats = []

        without_comments(children).each do | phone_type |
          if phone_type.name == 'availableFormats'
            formats = parse_formats(phone_type.children)
          else
            types[name2sym(phone_type.name)] =
                get_hash_from_xml(phone_type, :element)
          end
        end

        types = add_possible_if_not_exists(types)

        { types: types, formats: formats }
      end

      # method adds short number patterns to main data parsed from main xml
      def merge_short_with_main_type(country_id, type, data)
        data.each do |k, v|
          if @data[country_id][:types][type][k]
            @data[country_id][:types][type][k] += "|#{v}"
          else
            @data[country_id][:types][type][k] = v
          end
        end
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

      # method finds country by country prefix
      def get_country_by_code(country_code)
        match = @data.select { |k, v| v[:country_code] == country_code }
        if match.size > 1
          match = match.select { |k, v| v[:main_country_for_code] == 'true' }
        end

        match.keys.first
      end
    end
  end
end