require 'bigdecimal'
require 'bigdecimal/util'
require 'paperless_to_xero/decimal_helpers'

module PaperlessToXero
  class InvoiceItem
    include PaperlessToXero::DecimalHelpers
    
    class << self
      def fetch_vat_rate(vat_type)
        @vat_rates ||= {
          '5.5% (France, VAT on expenses)' => 1.055.to_d,
          '19.6% (France, VAT on expenses)' => 1.196.to_d,
          '7% (Germany, VAT on expenses)' => 1.07.to_d,
          '19% (Germany, VAT on expenses)' => 1.19.to_d,
          '25% (Denmark, VAT on expenses)' => 1.25.to_d,
          '21.5% (Ireland, VAT on expenses)' => 1.215.to_d,
          '15% (EU VAT ID)' => 1.15.to_d,
          '15% (VAT on expenses)' => 1.15.to_d,
          '17.5% (VAT on expenses)' => 1.175.to_d,
          'Zero Rated Expenses' => 0,
          '15% (Luxembourg, VAT on expenses)' => 1.15.to_d
        }
        @vat_rates[vat_type]
      end
    end
    
    attr_reader :description, :amount, :category, :vat_inclusive, :vat_inclusive_amount, :vat_exclusive_amount, :vat_amount, :vat_type
    
    def initialize(description, amount, vat_amount, category, vat_note = 'VAT - 15%', vat_inclusive = true)
      @amount, @vat_amount, @description, @category, @vat_inclusive = amount, vat_amount, description, category, vat_inclusive
      @vat_type = extract_vat_type(vat_note)
      
      vat_rate = fetch_vat_rate(vat_type)
      case vat_rate
      when BigDecimal
        decimal_amount = BigDecimal.new(@amount)
        decimal_vat_amount = @vat_amount.nil? ? nil : BigDecimal.new(@vat_amount)
        amounts_method = vat_inclusive ? :amounts_when_vat_inclusive : :amounts_when_vat_exclusive
        @vat_exclusive_amount, @vat_amount, @vat_inclusive_amount = self.send(amounts_method, decimal_amount, decimal_vat_amount)
      else
        amounts_when_zero_rated_or_non_vat(vat_rate)
      end
    end
    
    private
    
    def amounts_when_zero_rated_or_non_vat(vat_rate)
      @vat_inclusive_amount = @amount
      @vat_exclusive_amount = @amount
      @vat_amount = vat_rate.nil? ? nil : "0.00"
    end
    
    def fetch_vat_rate(vat_type)
      self.class.fetch_vat_rate(vat_type)
    end
    
    def extract_vat_type(vat_note)
      case vat_note
      when 'VAT - France - 5.5%'
        '5.5% (France, VAT on expenses)'
      when /Fr/
        '19.6% (France, VAT on expenses)'
      when 'VAT - Germany - 7%'
        '7% (Germany, VAT on expenses)'
      when /Germany/
        '19% (Germany, VAT on expenses)'
      when /Den/
        '25% (Denmark, VAT on expenses)'
      when /Irel/
        '21.5% (Ireland, VAT on expenses)'
      when /Sweden/
        '25% (Sweden, VAT on expenses)'
      when /Lux/
        '15% (Luxembourg, VAT on expenses)'
      when /VAT - EU/
        '15% (EU VAT ID)'
      when 'VAT - 15%'
        '15% (VAT on expenses)'
      when 'VAT - 17.5%'
        '17.5% (VAT on expenses)'
      when 'VAT - 0%'
        'Zero Rated Expenses'
      when 'No VAT'
        'No VAT'
      when 'VAT'
        '15% (VAT on expenses)'
      end
    end
  end
end
