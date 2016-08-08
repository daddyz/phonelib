module Phonelib
  # @private helper module for parsing raw libphonenumber data
  module DataImporterHelper
    # xml comments attributes names that should not be parsed
    XML_COMMENT_ATTRIBUTES = %w(text comment)
    # xml format attributes names
    XML_FORMAT_NAMES = %w(intlFormat format)

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

    # method for checking if element name is not a format element
    def not_format?(name)
      !XML_FORMAT_NAMES.include? name
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

    # get main body from parsed xml document
    def main_from_xml(file)
      xml_data = File.read(file)
      xml_data.force_encoding('utf-8')

      doc = Nokogiri::XML(xml_data)
      doc.elements.first.elements.first
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
