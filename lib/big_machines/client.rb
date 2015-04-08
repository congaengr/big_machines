module BigMachines
  class Client

    attr_reader :client
    attr_reader :headers

    # The partner.wsdl is used by default but can be changed by passing in a new :wsdl option.
    # A client_id can be
    def initialize(site_name, options={})
      @site_name = site_name
      raise "Valid Site Name must be provided" if @site_name.nil? || @site_name.empty?
      @process_var_name = options[:process_name] || "quotes_process"
      @logger = options[:logger] || false

      @namespaces = {
        "xmlns:bm" => "urn:soap.bigmachines.com"
      }

      @security_wsdl = File.dirname(__FILE__) + "/../../resources/security.wsdl.xml"
      @commerce_wsdl = File.dirname(__FILE__) + "/../../resources/commerce.wsdl.xml"

      @endpoint = "https://#{@site_name}.bigmachines.com/v1_0/receiver"

      @client = Savon.client(configuration)
    end

    def headers(type=:security)
      if type == :security
        category = "Security"
        schema = "https://#{@site_name}.bigmachines.com/bmfsweb/#{@site_name}/schema/v1_0/security/Security.xsd"
      else
        category = "Commerce"
        schema = "https://#{@site_name}.bigmachines.com/bmfsweb/#{@site_name}/schema/v1_0/commerce/#{@process_var_name}.xsd"
      end

      @headers = ''
      if @session_id
        @headers << %Q{<bm:userInfo xmlns:bm="urn:soap.bigmachines.com">
<bm:sessionId>#{@session_id}</bm:sessionId>
</bm:userInfo>}
      end

      @headers << %Q{
<bm:category xmlns:bm="urn:soap.bigmachines.com">#{category}</bm:category>
<bm:xsdInfo xmlns:bm="urn:soap.bigmachines.com">
<bm:schemaLocation>#{schema}</bm:schemaLocation>
</bm:xsdInfo>}.gsub(/\n/, '')

      @headers
    end

    # Public: Get the names of all wsdl operations.
    # List all available operations from the partner.wsdl
    def operations
      @client.operations
    end

    # Public: login
    #
    # Examples
    #
    #   client.login(username, password)
    #   # => {...}
    #
    # Returns Hash of login response and user info
    def login(username, password)
      result = nil
      message = {userInfo: {username: username, password: password}}
      response = self.security_call(:login, message)

      userInfo = response[:user_info]

      @session_id = userInfo[:session_id]

      @security_client = Savon.client(configuration)

      response[:status][:success]
    end
    alias_method :authenticate, :login

    def set_session_currency(currency)
      security_call(:set_session_currency, sessionCurrency: currency)
    end

    # Commerce API
    #
    # <bm:getTransaction xmlns:bm="urn:soap.bigmachines.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    #   <bm:transaction>
    #     <bm:id/>
    #     <bm:return_specific_attributes>
    #       <bm:documents>
    #         <bm:document>
    #           <bm:var_name>quote_process</bm:var_name>
    #           <bm:attributes>
    #             <bm:attribute>_document_number</bm:attribute>
    #           </bm:attributes>
    #         </bm:document>
    #       </bm:documents>
    #     </bm:return_specific_attributes>
    #   </bm:transaction>
    # </bm:getTransaction>
    def get_transaction(id, document_var_name='quote_process')
      transaction = {
        transaction: {
          id: id,
          return_specific_attributes: {
            documents: {
              document: {
                var_name: document_var_name
              }
            }
          }
        }
      }

      result = commerce_call(:get_transaction, transaction)
      BigMachines::Transaction.new(result)
    end

    # <bm:updateTransaction xmlns:bm="urn:soap.bigmachines.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    #   <bm:transaction>
    #     <bm:id>26539349</bm:id>
    #     <bm:data_xml>
    #       <bm:quote_process bm:bs_id="26539349" bm:data_type="0" bm:document_number="1">
    #         <bm:opportunityName_quote>Test Oppty Auto Approval TinderBox</bm:opportunityName_quote>
    #         <bm:siteName_quote>MY DUMMY SITE</bm:siteName_quote>
    #       </bm:quote_process>
    #     </bm:data_xml>
    #     <bm:action_data>
    #       <bm:action_var_name>_update_line_items</bm:action_var_name>
    #     </bm:action_data>
    #   </bm:transaction>
    # </bm:updateTransaction>
    def update_transaction(id, data={})

      # :opportunityName_quote => 'Test Oppty Auto Approval TinderBox 12',
      # :siteName_quote => 'My Dummy Site'
      quote_process_data = {
        :"@bs_id" => id,
        :"@data_type" => 0,
        :"@document_number" => 1
      }.merge(data)

      transaction = {
        transaction: {
          id: id,
          data_xml: {
            quote_process: quote_process_data
          },
          action_data: {
            action_var_name: '_update_line_items'
          }
        }
      }

      commerce_call(:update_transaction, transaction)
    end

    def get_file_attachments(transaction_id, variable_name: "uploadEngineeringTemplate_File", mode: "content", inline: true)

      export = {
        mode: mode,
        inline: inline,
        attachments: {
          attachment: {
            document_number: 1,
            variable_name: variable_name
          }
        },
        transaction: {
          process_var_name: @process_var_name,
          id: transaction_id
        }
      }

      result = commerce_call(:export_file_attachments, export)

      attachments = []
      result[:attachments].each do |key, data|
        attachments << BigMachines::Attachment.new(data)
      end

      attachments
    end

    def upload_attachment(transaction_id, file, variable_name: 'uploadEngineeringTemplate_File')

      import = {
        mode: 'update',
        attachments: {
          attachment: {
            document_number: 1,
            variable_name: variable_name,
            filename: file.path,
            file_content: Base64.strict_encode64(file.read)
          }
        },
        transaction: {
          process_var_name: @process_var_name,
          id: transaction_id
        }
      }
      commerce_call(:import_file_attachments, import)
    end

    def delete_attachment(transaction_id, variable_name: 'uploadEngineeringTemplate_File')
      delete = {
        mode: 'delete',
        attachments: {
          attachment: {
            document_number: 1,
            variable_name: variable_name
          }
        },
        transaction: {
          process_var_name: @process_var_name,
          id: transaction_id
        }
      }
      commerce_call(:import_file_attachments, delete)
    end

    # Supports the following No Argument methods:
    #   get_user_info
    #   logout
    def method_missing(method, *args)
      if [:get_user_info, :logout].include?(method)
        call_soap_api(security_client, method, *args)
      else
        super
      end
    end

    protected

    def configuration(custom={})
      {
        wsdl: @security_wsdl,
        endpoint: @endpoint,
        soap_header: headers(:security),
        filters: [:password],
        convert_request_keys_to: :none,
        pretty_print_xml: true,
        logger: @logger,
        log: @logger != false
      }.merge(custom)
    end

    def commerce_client
      @commerce_client ||= client_api(@commerce_wsdl)
    end

    def security_client
      @security_client ||= client_api(@security_wsdl)
    end

    def client_api(wsdl)
      category = wsdl.include?('security') ? :security : :commerce
      client = Savon.client(configuration(wsdl: wsdl, soap_header: headers(category)))
    end

    def security_call(method, message_hash={})
      call_soap_api(security_client, method, message_hash)
    end

    def commerce_call(method, message_hash={})
      call_soap_api(commerce_client, method, message_hash)
    end

    def call_soap_api(client, method, message={})
      response = client.call(method.to_sym, message: message)
      # Convert SOAP XML to Hash
      response = response.to_hash

      # Get Response Body
      response = response["#{method}_response".to_sym]

      # Raise error when response contains errors
      if response.is_a?(Hash) && response[:status] && response[:status][:success] == false
        raise Savon::Error.new(response[:status][:message])
      end

      return response
    end

  end
end