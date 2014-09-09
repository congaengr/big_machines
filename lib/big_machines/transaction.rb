module BigMachines
  class Transaction
    attr_reader :raw_transaction

    def initialize(response)
      @raw_transaction = response
      # Metadata
      @transaction = response[:transaction]
      # Quote
      @quote_process = @transaction[:data_xml][:quote_process]
      # Quote Line Items
      @line_process = @quote_process[:sub_documents][:line_process]
    end

    def method_missing(method, *args)
      @transaction[method]
    end

    def quote
      @quote_process
    end

    def quote_line_items
      @line_process
    end

  end
end