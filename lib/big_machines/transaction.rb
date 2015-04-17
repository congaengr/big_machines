module BigMachines
  class Transaction
    attr_reader :raw_transaction

    def initialize(response)
      @raw_transaction = response
      # Metadata
      @transaction = response["transaction"]
      # Quote
      @quote_process = @transaction["data_xml"]["quote_process"]
      # Line Items
      @line_process = if @quote_process["sub_documents"].is_a?(Hash)
        @quote_process["sub_documents"]["line_process"]
      else
        []
      end
    end

    def method_missing(method, *args)
      @transaction[method.to_s]
    end

    def quote
      @quote_process
    end

    def quote_line_items
      @line_process
    end

  end
end