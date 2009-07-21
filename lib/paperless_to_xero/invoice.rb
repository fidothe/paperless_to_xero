require 'paperless_to_xero/invoice_item'

module PaperlessToXero
  class Invoice
    attr_reader :date, :merchant, :reference_id, :currency
    
    def initialize(date, merchant, reference_id, currency = 'GBP')
      @date, @merchant, @reference_id, @currency = date, merchant, reference_id, currency
    end
    
    def items
      @items ||= []
    end
    
    def add_item(description, amount, category, vat_note, vat_inclusive)
      items << PaperlessToXero::InvoiceItem.new(description, amount, category, vat_note, vat_inclusive)
    end
    
    def serialise_to_csv(csv)
      serialising_items = items.dup
      first_item = serialising_items.shift
      
      marked_merchant = currency != 'GBP' ? merchant + " (#{currency})" : merchant
      unless first_item.nil?
        csv << [marked_merchant, reference_id, date.strftime('%d/%m/%Y'), date.strftime('%d/%m/%Y'), 
                nil, nil, nil, first_item.description, '1', 
                first_item.vat_exclusive_amount, first_item.category, first_item.vat_type, first_item.vat_amount, 
                nil, nil, nil, nil]
      end
      serialising_items.each do |item|
        csv << [nil, reference_id, nil, nil, 
                nil, nil, nil, item.description, '1', 
                item.vat_exclusive_amount, item.category, item.vat_type, item.vat_amount, 
                nil, nil, nil, nil]
      end
    end
  end
end