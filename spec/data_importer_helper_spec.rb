# frozen_string_literal: true

require 'phonelib'
require 'phonelib/data_importer_helper'
require 'phonelib/data_importer'
require 'nokogiri'

describe Phonelib::DataImporterHelper do
  let(:helper) do
    Class.new do
      include Phonelib::DataImporterHelper
    end.new
  end

  describe '#hash_from_xml' do
    it 'keeps possible-length metadata alongside the existing regex' do
      xml = Nokogiri::XML(<<-XML)
        <type>
          <nationalNumberPattern>\\d{6,12}</nationalNumberPattern>
          <possibleLengths national="6,[8-10],12" localOnly="4,[5-6]"/>
        </type>
      XML

      data = helper.send(:hash_from_xml, xml.root, :element)

      expect(data[Phonelib::Core::POSSIBLE_PATTERN]).to eq(
        '\\d{6}|\\d{8,10}|\\d{12}'
      )
      expect(data[Phonelib::Core::POSSIBLE_LENGTHS]).to eq([6, 8, 9, 10, 12])
      expect(data[Phonelib::Core::POSSIBLE_LOCAL_ONLY_LENGTHS]).to eq([4, 5, 6])
    end

    it 'does not add length metadata when the XML has no possible lengths' do
      xml = Nokogiri::XML(<<-XML)
        <type>
          <nationalNumberPattern>\\d{6,12}</nationalNumberPattern>
        </type>
      XML

      data = helper.send(:hash_from_xml, xml.root, :element)

      expect(data).not_to have_key(Phonelib::Core::POSSIBLE_LENGTHS)
      expect(data).not_to have_key(Phonelib::Core::POSSIBLE_LOCAL_ONLY_LENGTHS)
    end

    it 'preserves the metadata sentinel for an unsupported number type' do
      xml = Nokogiri::XML(<<-XML)
        <type>
          <nationalNumberPattern>\d{6}</nationalNumberPattern>
          <possibleLengths national="-1"/>
        </type>
      XML

      data = helper.send(:hash_from_xml, xml.root, :element)

      expect(data[Phonelib::Core::POSSIBLE_LENGTHS]).to eq([-1])
    end

    it 'rejects possible lengths outside libphonenumber bounds' do
      xml = Nokogiri::XML(<<-XML)
        <type>
          <nationalNumberPattern>\d{18}</nationalNumberPattern>
          <possibleLengths national="1-18"/>
        </type>
      XML

      expect do
        helper.send(:hash_from_xml, xml.root, :element)
      end.to raise_error(ArgumentError, 'possible length out of range: 18')
    end

    it 'rejects malformed possible-length brackets' do
      xml = Nokogiri::XML(<<-XML)
        <type>
          <nationalNumberPattern>\d{12}</nationalNumberPattern>
          <possibleLengths national="1[2]"/>
        </type>
      XML

      expect do
        helper.send(:hash_from_xml, xml.root, :element)
      end.to raise_error(ArgumentError, 'invalid possible length: 1[2]')
    end
  end
end

describe Phonelib::DataImporter::Importer do
  describe '#types_and_formats' do
    it 'synthesizes general possible-length metadata from concrete types' do
      xml = Nokogiri::XML(<<-XML)
        <territory>
          <generalDesc>
            <nationalNumberPattern>\\d{6,10}</nationalNumberPattern>
          </generalDesc>
          <fixedLine>
            <nationalNumberPattern>\\d{8}</nationalNumberPattern>
            <possibleLengths national="8,10" localOnly="7"/>
          </fixedLine>
          <mobile>
            <nationalNumberPattern>\\d{9}</nationalNumberPattern>
            <possibleLengths national="7-9" localOnly="6-7"/>
          </mobile>
          <pager>
            <nationalNumberPattern>(?!)</nationalNumberPattern>
            <possibleLengths national="-1"/>
          </pager>
        </territory>
      XML

      data = described_class.allocate.send(:types_and_formats, xml.root.children)
      general = data[:types][Phonelib::Core::GENERAL]

      expect(general[Phonelib::Core::POSSIBLE_PATTERN]).to eq(
        '\\d{8}|\\d{10}|\\d{7,9}'
      )
      expect(general[Phonelib::Core::POSSIBLE_LENGTHS]).to eq([7, 8, 9, 10])
      expect(general[Phonelib::Core::POSSIBLE_LOCAL_ONLY_LENGTHS]).to eq([6])
    end
  end

  describe '#merge_short_with_main_type' do
    it 'merges structured possible-length metadata without changing regex data' do
      importer = described_class.allocate
      importer.instance_variable_set(:@data, {
        'XY' => {
          types: {
            short_code: {
              short: {
                Phonelib::Core::POSSIBLE_PATTERN => '\\d{3}|\\d{5}',
                Phonelib::Core::POSSIBLE_LENGTHS => [3, 5],
                Phonelib::Core::POSSIBLE_LOCAL_ONLY_LENGTHS => [2]
              }
            }
          }
        }
      })

      importer.send(:merge_short_with_main_type, 'XY', :short_code, {
        Phonelib::Core::POSSIBLE_PATTERN => '\\d{4}|\\d{5}',
        Phonelib::Core::POSSIBLE_LENGTHS => [4, 5],
        Phonelib::Core::POSSIBLE_LOCAL_ONLY_LENGTHS => [1, 2]
      })

      data = importer.instance_variable_get(:@data)['XY'][:types][:short_code][:short]
      expect(data[Phonelib::Core::POSSIBLE_PATTERN]).to eq(
        '\\d{3}|\\d{5}|\\d{4}|\\d{5}'
      )
      expect(data[Phonelib::Core::POSSIBLE_LENGTHS]).to eq([3, 4, 5])
      expect(data[Phonelib::Core::POSSIBLE_LOCAL_ONLY_LENGTHS]).to eq([1, 2])
    end
  end
end
