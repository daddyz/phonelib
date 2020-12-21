require 'phonelib/data_importer_helper'

module Phonelib
  # @private module processes creation of data files needed for this gem
  module DataImporter
    require 'nokogiri'

    # official libphonenumber repo for cloning
    REPO = 'https://github.com/googlei18n/libphonenumber.git'

    # importing function
    def self.import
      Importer.new
    end

    # @private class with functionality for importing data
    class Importer
      include Phonelib::DataImporterHelper

      # countries that can have double country prefix in number
      DOUBLE_COUNTRY_CODES_COUNTRIES = %w(IN DE BR IT NO PL CU VN)

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
      TIMEZONES_DIR = 'resources/timezones/'

      # class initialization method
      def initialize
        @destination = File.path(
          "#{File.dirname(__FILE__)}/../../data/libphonenumber/")
        @data = {}
        @prefixes = {}
        @geo_names = []
        @timezones = []
        @carriers = []
        @countries = {}

        run_import
      end

      private

      # running import method
      def run_import
        clone_repo
        import_main_data
        import_short_data
        import_alternate_formats
        import_geocoding_data
        import_timezone_data
        import_carrier_data
        import_country_names
        save_data_file
        save_extended_data_file
      end

      # method clones libphonenumber repo to local dir
      def clone_repo
        repo = Phonelib::DataImporter::REPO

        system("rm -rf #{@destination}")
        cloned = system("git clone #{repo} #{@destination} --depth 1 -b master")
        fail 'Could not clone repo' unless cloned
      end

      # method parses main data file
      def import_main_data
        puts 'IMPORTING MAIN DATA'
        main_from_xml("#{@destination}#{MAIN_FILE}").elements.each do |el|
          # each country
          country = hash_from_xml(el, :attributes)
          country.merge! types_and_formats(el.children)
          country = add_double_country_flag country
          if country[Core::NATIONAL_PREFIX_TRANSFORM_RULE]
            country[Core::NATIONAL_PREFIX_TRANSFORM_RULE].gsub!('$', '\\')
          end
          @data[country[:id]] = country
        end
      end

      # method parses main data file
      def import_short_data
        puts 'IMPORTING SHORT NUMBER DATA'
        main_from_xml("#{@destination}#{SHORT_DATA_FILE}").elements.each do |el|
          # each country
          country = hash_from_xml(el, :attributes)
          country.merge! types_and_formats(el.children)

          country[:types].each do |type, data|
            merge_short_with_main_type(country[:id], type, data)
          end
        end
      end

      # method parses alternate formats file
      def import_alternate_formats
        puts 'IMPORTING ALTERNATE FORMATS'

        main_from_xml("#{@destination}#{FORMATS_FILE}").elements.each do |el|
          el.children.each do |phone_type|
            next unless phone_type.name == 'availableFormats'

            country_code = country_by_code(el.attribute('countryCode').value)
            @data[country_code][:formats] += parse_formats(phone_type.children)
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

      # import country names
      def import_country_names
        puts 'IMPORTING COUNTRY NAMES'

        require 'open-uri'
        require 'csv'
        io = open('http://api.geonames.org/countryInfoCSV?username=demo&style=full')
        csv = CSV.new(io, {col_sep: "\t"})
        csv.each do |row|
          next if row[0].nil? || row[0].start_with?('#') || row[0].empty?

          @countries[row[0]] = row[4]
        end
      end

      # adds double country code flag in case country allows
      def add_double_country_flag(country)
        if DOUBLE_COUNTRY_CODES_COUNTRIES.include?(country[:id])
          country[:double_prefix] = true
        end
        country
      end

      # method extracts formats and types from xml data
      def types_and_formats(children)
        result = { types: {}, formats: [] }

        without_comments(children).each do |phone_type|
          if phone_type.name == 'references'
            next
          elsif phone_type.name == 'availableFormats'
            result[:formats] = parse_formats(phone_type.children)
          else
            result[:types][name2sym(phone_type.name)] =
                hash_from_xml(phone_type, :element)
          end
        end

        fill_possible_to_types_if_nil(result)
      end

      # method adds short number patterns to main data parsed from main xml
      def merge_short_with_main_type(country_id, type, data)
        @data[country_id][:types][type] ||= {}
        @data[country_id][:types][type][Core::SHORT] ||= {}
        data.each do |k, v|
          if @data[country_id][:types][type][Core::SHORT][k]
            @data[country_id][:types][type][Core::SHORT][k] += "|#{v}"
          else
            @data[country_id][:types][type][Core::SHORT][k] = v
          end
        end
      end

      # adds possible pattern in case it doesn't exists
      def fill_possible_to_types_if_nil(result)
        result[:types].each do |type, data|
          if data[Core::VALID_PATTERN] && !data[Core::POSSIBLE_PATTERN]
            result[:types][type][Core::POSSIBLE_PATTERN] = case type
                  when Core::GENERAL
                    national_possible result[:types]
                  else
                    data[Core::VALID_PATTERN]
                  end
          end
        end
        result
      end

      # take all possible patters from all types
      def national_possible(types)
        types.map { |k, v| v[:possible_number_pattern] }.
            compact.map { |e| e.split('|') }.flatten.uniq.join('|')
      end

      # method parses xml for formats data
      def parse_formats(formats_children)
        without_comments(formats_children).map do |format|
          current_format = hash_from_xml(format, :children)

          without_comments(format.children).each do |f|
            current_format[name2sym(f.name)] =
                str_clean(f.children.first, not_format?(f.name))
          end

          current_format
        end
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
      def country_by_code(country_code)
        match = @data.select { |_k, v| v[:country_code] == country_code }
        if match.size > 1
          match = match.select { |_k, v| v[:main_country_for_code] == 'true' }
        end

        match.keys.first
      end
    end
  end
end
