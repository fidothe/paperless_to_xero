require 'csv'

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
          notes = extract_notes(notes_field)
          invoice = PaperlessToXero::Invoice.new(date, merchant, reference, extract_currency(notes))
          if extras.empty?
            invoice.add_item(description, amount, category, extract_vat_note(vat, notes), true)
          else
            raise RangeError, "input CSV row is badly formatted" unless extras.size % 6 == 0
            items = chunk_extras(extras)
            items.each do |item|
              description, paperless_currency, amount, unknown, category, notes_field = item
              category = category[0..2]
              invoice.add_item(description, amount, category, extract_vat_note(vat, extract_notes(notes_field)), true)
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
        return item if item.match(/^[A_Z]{3}$/)
        case item
        when "€"
          return "EUR"
        when "$"
          return "USD"
        end
      end
      "GBP"
    end
    
    def extract_vat_note(vat, notes)
      notes.each do |item|
        return item if item.match(/^VAT/)
      end
      
      case vat
      when "0.00"
        'Zero Rated Expenses'
      when nil
        'No VAT'
      else
        'VAT - 15%'
      end
    end
  end
end
