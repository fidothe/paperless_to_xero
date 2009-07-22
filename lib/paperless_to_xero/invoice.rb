require 'bigdecimal'
require 'paperless_to_xero/decimal_helpers'
require 'paperless_to_xero/invoice_item'

module PaperlessToXero
  class Invoice
    include PaperlessToXero::DecimalHelpers
    
    attr_reader :date, :merchant, :reference_id, :currency, :total, :ex_vat_total, :inc_vat_total, :vat_total
    
    def initialize(date, merchant, reference_id, total, vat, vat_inclusive = true, currency = 'GBP')
      @date, @merchant, @reference_id = date, merchant, reference_id
      @total, @vat_inclusive, @currency = total, vat_inclusive, currency
      decimal_total = BigDecimal.new(total)
      decimal_vat = BigDecimal.new(vat)
      @ex_vat_total, @vat_total, @inc_vat_total = amounts_when_vat_inclusive(decimal_total, decimal_vat)
    end
    
    def items
      @items ||= []
    end
    
    def vat_inclusive?
      @vat_inclusive
    end
    
    def add_item(description, amount, vat_amount, category, vat_note)
      items << PaperlessToXero::InvoiceItem.new(description, amount, vat_amount, category, vat_note, @vat_inclusive)
    end
    
    def serialise_to_csv(csv)
      serialising_items = items.dup
      first_item = serialising_items.shift
      
      marked_merchant = currency != 'GBP' ? merchant + " (#{currency})" : merchant
      unless first_item.nil?
        csv << [marked_merchant, reference_id, date.strftime('%d/%m/%Y'), date.strftime('%d/%m/%Y'), 
                ex_vat_total, vat_total, inc_vat_total, first_item.description, '1', 
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