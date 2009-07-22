require 'csv'
require 'date'

module PaperlessToXero
  class Converter
    attr_reader :input_path, :output_path
    
    def initialize(input_path, output_path)
      @input_path, @output_path = input_path, output_path
    end
    
    def invoices
      @invoices ||= []
    end
    
    def parse
      input_csv = CSV.read(input_path)
      # remove Paperless header row
      input_csv.shift
      
      input_csv.each do |row|
        date, merchant, paperless_currency, amount, vat, category, payment_method, notes_field, description, reference, status, *extras = row
        negative = amount.index('--') == 0
        category = category[0..2] unless category.nil?
        unless negative # negative stuff ought to be a credit note. not sure if that works...
          # process amounts for commas added by Paperless
          amount = amount.tr(',', '') unless amount.nil?
          vat = vat.tr(',', '') unless vat.nil?
          notes = extract_notes(notes_field)
          invoice = PaperlessToXero::Invoice.new(extract_date(date), merchant, reference, amount, vat, inc_vat?(notes), extract_currency(notes))
          if extras.empty?
            invoice.add_item(description, amount, vat, category, extract_vat_note(vat, notes))
          else
            raise RangeError, "input CSV row is badly formatted" unless extras.size % 6 == 0
            items = chunk_extras(extras)
            items.each do |item|
              description, paperless_currency, amount, unknown, category, notes_field = item
              category = category[0..2]
              notes = extract_notes(notes_field)
              vat_amount = extract_vat_amount(notes)
              vat_note = extract_vat_note(vat_amount, notes)
              invoice.add_item(description, amount, vat_amount, category, vat_note)
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
    
    def extract_vat_note(vat_amount, notes)
      notes.each do |item|
        return item if item.match(/^VAT/)
      end
      
      case vat_amount
      when "0.00"
        'VAT - 0%'
      when nil
        'No VAT'
      else
        'VAT - 15%'
      end
    end
  end
end
