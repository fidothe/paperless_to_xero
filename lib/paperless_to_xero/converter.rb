require 'csv'
require 'date'
require 'paperless_to_xero/errors'

module PaperlessToXero
  PAPERLESS_HEADER_ROW = ["Date","Merchant","Currency","Amount","Tax","Category","Payment Method","Notes","Description","Reference #","Status"]
  class Converter
    VAT_RATE_CHANGE_2008_12_01 = Date.parse('2008-12-01')
    VAT_RATE_CHANGE_2010_01_01 = Date.parse('2010-01-01')
    VAT_RATE_CHANGE_2011_01_04 = Date.parse('2011-01-04')
    attr_reader :input_path, :output_path
    
    def initialize(input_path, output_path)
      @input_path, @output_path = input_path, output_path
    end
    
    def invoices
      @invoices ||= []
    end
    
    def verify_header_row!(row)
      raise UnknownHeaderRow unless row == PaperlessToXero::PAPERLESS_HEADER_ROW
    end
    
    def parse
      input_csv = CSV.read(input_path)
      # verify Paperless header row
      verify_header_row!(input_csv.shift)
      
      input_csv.each_with_index do |row, index|
        line_number = index + 1
        date, merchant, paperless_currency, amount, vat, category, payment_method, notes_field, description, reference, status, *extras = row
        negative = amount.index('--') == 0
        category = category[0..2] unless category.nil?
        unless negative # negative stuff ought to be a credit note. not sure if that works...
          # process amounts for commas added by Paperless
          amount = amount.tr(',', '') unless amount.nil?
          vat = vat.tr(',', '') unless vat.nil?
          notes = extract_notes(notes_field)
          total_vat = vat.nil? ? "0.00" : vat
          invoice = PaperlessToXero::Invoice.new(extract_date(date), merchant, reference, amount, total_vat, inc_vat?(notes), extract_currency(notes))
          if extras.empty?
            begin
              invoice.add_item(description, amount, vat, category, extract_vat_note(invoice.date, vat, notes))
            rescue
              raise BadItem.new(line_number, row, "Couldn't process this item")
            end
          else
            raise IncorrectNumberOfColumns.new(line_number, row, "Extra items are badly formatted") unless extras.size % 6 == 0
            items = chunk_extras(extras)
            items.each do |item|
              begin
                description, paperless_currency, amount, unknown, category, notes_field = item
                category = category[0..2]
                notes = extract_notes(notes_field)
                vat_amount = extract_vat_amount(notes)
                vat_note = extract_vat_note(invoice.date, vat_amount, notes)
                invoice.add_item(description, amount, vat_amount, category, vat_note)
              rescue
                raise BadItem.new(line_number, row, "Couldn't process this item")
              end
            end
          end
          invoices << invoice
          
          # currency fudging
          # actual_currency_match = notes.nil? ? nil : notes.match(/(\$|€|DKK|USD|EUR)/)
          # actual_currency = actual_currency_match.nil? ? nil : actual_currency_match[1]
          # 
          # description = description + " (#{actual_currency})" unless actual_currency.nil?
        end
      end
    end
    
    def convert!
      # grab the input
      parse
      # open the output CSV
      CSV.open(output_path, 'w') do |writer|
        # Xero header row
        writer << ['ContactName','InvoiceNumber','InvoiceDate','DueDate','SubTotal',
                   'TotalTax','Total','Description','Quantity','UnitAmount','AccountCode','TaxType','TaxAmount',
                   'TrackingName1','TrackingOption1','TrackingName2','TrackingOption2']
        
        # body rows
        invoices.each do |invoice|
          invoice.serialise_to_csv(writer)
        end
      end
    end
    
    private
    
    def inc_vat?(notes)
      notes.each do |item|
        return false if item.match(/^Ex[ -]?VAT$/i)
      end
      true
    end
    
    def extract_date(date_string)
      ds, day, month, year = date_string.match(/([0-9]{2})\/([0-9]{2})\/([0-9]{4})/).to_a
      Date.parse("#{year}-#{month}-#{day}")
    end
    
    def chunk_extras(extras)
      duped_extras = extras.dup
      (1..(extras.size / 6)).inject([]) do |chunked, i|
        chunked << duped_extras.slice!(0..5)
      end
    end
    
    def extract_notes(notes_field)
      notes = notes_field.nil? ? [] : notes_field.split(';')
      notes.collect { |item| item.strip }
    end
    
    def extract_currency(notes)
      notes.each do |item|
        return item if item.match(/^[A-Z]{3}$/)
        case item
        when "€"
          return "EUR"
        when "$"
          return "USD"
        end
      end
      "GBP"
    end
    
    def extract_vat_amount(notes)
      notes.each do |item|
        return item if item.match(/^[0-9]+\.[0-9]{1,2}$/)
      end
      nil
    end
    
    def extract_vat_note(date, vat_amount, notes)
      notes.each do |item|
        return item if item.match(/^VAT/)
      end
      
      case vat_amount
      when "0.00"
        'VAT - 0%'
      when nil
        'No VAT'
      else
        base_uk_vat_rate_on_date(date)
      end
    end
    
    def base_uk_vat_rate_on_date(date)
      return 'VAT - 15%' if date >= VAT_RATE_CHANGE_2008_12_01 && date < VAT_RATE_CHANGE_2010_01_01
      return 'VAT - 17.5%' if date >= VAT_RATE_CHANGE_2010_01_01 && date < VAT_RATE_CHANGE_2011_01_04
      return 'VAT - 20%' if date >= VAT_RATE_CHANGE_2011_01_04
      'VAT - 17.5%'
    end
  end
end
