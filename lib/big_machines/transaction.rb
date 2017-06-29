module BigMachines
  class Transaction
    attr_reader :raw_transaction

    def initialize(response)
      @raw_transaction = response
      # Metadata
      @transaction = response['transaction']
      data_xml = @transaction['data_xml']

      # Quote/Transaction
      # The named element can be different between instances, but there
      # will only be a single child under data_xml that will be the quote.
      quote_key = data_xml.keys.first
      @quote_process = data_xml[quote_key]

      @quote_process ||= {}
      # Line Items exist under sub_documents.
      # <sub_documents><line_process></line_process></sub_documents>
      sub_documents = @quote_process['sub_documents']

      @line_process = if sub_documents.is_a?(Hash)
        # The named element can be different between instances, but there
        # will only be a single child under sub_documents that will be the line data.
        line_key = sub_documents.keys.first
        lines = sub_documents[line_key]
        # Ensure lines are an array.  A single item gets converted to a Hash
        if lines.is_a?(Hash)
          # Re-assign and wrap Hash in array
          sub_documents[line_key] = [lines]
        else
          lines
        end
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
    alias transaction quote

    def quote_line_items
      @line_process
    end
    alias transaction_line_items quote_line_items
  end
end
