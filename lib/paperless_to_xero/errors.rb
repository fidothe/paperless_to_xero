module PaperlessToXero
  class UnknownHeaderRow < StandardError; end
  class RowError < StandardError
    def initialize(line_number, row, explanation = "")
      @line_number, @row, @explanation = line_number, row, explanation
    end
    
    def to_s
      "Error processing line #{@line_number.to_s}: #{@explanation}. Row was #{@row.inspect}"
    end
  end
  
  class IncorrectNumberOfColumns < RowError; end
  class BadItem < RowError; end
end