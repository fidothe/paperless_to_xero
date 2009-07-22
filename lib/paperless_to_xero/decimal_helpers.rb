module PaperlessToXero
  module DecimalHelpers
    def amounts_when_vat_inclusive(decimal_inc_vat_amount, decimal_vat_amount)
      vat_inclusive_amount = formatted_decimal(decimal_inc_vat_amount)
      vat_amount = formatted_decimal(decimal_vat_amount)
      decimal_ex_vat_amount = decimal_inc_vat_amount - decimal_vat_amount
      vat_exclusive_amount = formatted_decimal(decimal_ex_vat_amount)
      [vat_exclusive_amount, vat_amount, vat_inclusive_amount]
    end
    
    def amounts_when_vat_exclusive(decimal_ex_vat_amount, decimal_vat_amount)
      vat_exclusive_amount = formatted_decimal(decimal_ex_vat_amount)
      vat_amount = formatted_decimal(decimal_vat_amount)
      decimal_inc_vat_amount = decimal_ex_vat_amount + decimal_vat_amount
      vat_inclusive_amount = formatted_decimal(decimal_inc_vat_amount)
      [vat_exclusive_amount, vat_amount, vat_inclusive_amount]
    end
    
    def formatted_decimal(value)
      value = value.to_s('F')
      value = value + '0' unless value.index('.') < value.size - 2
      value
    end
  end
end