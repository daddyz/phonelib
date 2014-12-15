module Phonelib
  module DataImporter
    require 'nokogiri'

    REPO = 'https://github.com/googlei18n/libphonenumber.git'

    def self.import
      Importer.new
    end

    class Importer
      MAIN_FILE = 'resources/PhoneNumberMetadata.xml'
      FORMATS_FILE = 'resources/PhoneNumberAlternateFormats.xml'
      GEOCODING_DIR = 'resources/geocoding/en/'
      CARRIER_DIR = 'resources/carrier/en/'
      TIMEZONES_DIR= 'resources/timezones/'

      XML_COMMENT_ATTRIBUTES = %w(text comment)
      XML_FORMAT_NAMES = %w(intlFormat format)

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
        import_alternate_formats
        import_geocoding_data
        import_timezone_data
        import_carrier_data
        save_data_file
      end

      private

      def save_data_file
        data_file = File.path("#{@destination}/../phone_data.dat")

        File.open(data_file, 'wb+') do |f|
          Marshal.dump(@data, f)
        end

        ext_file = File.path("#{@destination}/../extended_data.dat")
        extended = {
          prefixes: @prefixes,
          geo_names: @geo_names,
          timezones: @timezones,
          carriers: @carriers
        }
        File.open(ext_file, 'wb+') do |f|
          Marshal.dump(extended, f)
        end
        puts 'DATA SAVED'
      end

      def clone_repo
        repo = Phonelib::DataImporter::REPO

        system("rm -rf #{@destination}")
        cloned = system("git clone #{repo} #{@destination} --depth 1 -b master")
        raise 'Could not clone repo' unless cloned
      end

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

          @data[country[:id]] = country
        end
      end

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

      def import_geocoding_data
        puts 'IMPORTING GEOCODING DATA'
        import_raw_files_data("#{@destination}#{GEOCODING_DIR}*",
                              @geo_names,
                              :g)
      end

      def import_timezone_data
        puts 'IMPORTING TIMEZONES DATA'
        import_raw_files_data("#{@destination}#{TIMEZONES_DIR}*",
                              @timezones,
                              :t)
      end

      def import_carrier_data
        puts 'IMPORTING CARRIER DATA'
        import_raw_files_data("#{@destination}#{CARRIER_DIR}*",
                              @carriers,
                              :c)
      end

      def without_comments(data)
        data.select do |el|
          !XML_COMMENT_ATTRIBUTES.include? el.name
        end
      end

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

      def is_not_format(name)
        !XML_FORMAT_NAMES.include? name
      end

      def main_from_xml(file)
        xml_data = File.read(file)
        xml_data.force_encoding("utf-8")

        doc = Nokogiri::XML(xml_data)
        doc.elements.first.elements.first
      end

      def get_country_by_code(country_code)
        match = @data.select { |k, v| v[:country_code] == country_code }
        if match.size > 1
          match = match.select { |k, v| v[:main_country_for_code] == 'true' }
        end

        match.keys.first
      end

      def str_clean(s, white_space = true)
        s.to_s.tr(white_space ? " \n" : "\n", '')
      end

      def name2sym(name)
        camel2snake(name).to_sym
      end

      def camel2snake(s)
        s.gsub(/[A-Z]+/) { |m| "_#{m.downcase}" }
      end
    end
  end
end