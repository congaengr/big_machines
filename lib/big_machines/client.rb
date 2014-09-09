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

      @namespaces = {
        "xmlns:bm" => "urn:soap.bigmachines.com"
      }

      @security_wsdl = File.dirname(__FILE__) + "/../../resources/security.wsdl.xml"
      @commerce_wsdl = File.dirname(__FILE__) + "/../../resources/commerce.wsdl.xml"

      @endpoint = "https://#{@site_name}.bigmachines.com/v1_0/receiver"

      @client = Savon.client(
        wsdl: @security_wsdl,
        endpoint: @endpoint,
        soap_header: headers(:security),
        convert_request_keys_to: :none,
        pretty_print_xml: true
      )
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

    # Public: Get the names of all wsdl operations.
    #
    # Supports a username/password (with token) combination or session_id/server_url pair.
    #
    # Examples
    #
    #   client.login(username: 'test', password: 'password_and_token')
    #   # => {...}
    #
    #   client.login(session_id: 'abcd1234', server_url: 'https://na1.salesforce.com/')
    #   # => {...}
    #
    # Returns Hash of login response and user info
    def login(options={})
      result = nil
      if options[:username] && options[:password]
        message = {userInfo: {username: options[:username], password: options[:password]}}
        response = self.security_call(:login, message)

        userInfo = response[:user_info]

        @session_id = userInfo[:session_id]
      else
        raise ArgumentError.new("Must provide username/password or session_id/server_url.")
      end

      @security_client = Savon.client(
        wsdl: @security_wsdl,
        endpoint: @endpoint,
        soap_header: headers(:security),
        convert_request_keys_to: :none,
        pretty_print_xml: true
      )

      # If a session_id/server_url were passed in then invoke get_user_info for confirmation.
      # Method missing to call_soap_api
      result = self.get_user_info if options[:session_id]

      result
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
    def get_transaction(id)
      transaction = {
        transaction: {
          id: id,
          return_specific_attributes: {
            documents: {
              document: {
                var_name: "quote_process"
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
      transaction = {
        transaction: {
          id: id,
          data_xml: {
            quote_process: {
              :"@bs_id" => id,
              :"@data_type" => 0,
              :"@document_number" => 1,
              :opportunityName_quote => 'Test Oppty Auto Approval TinderBox 12',
              :siteName_quote => 'My Dummy Site'
            }
          },
          action_data: {
            action_var_name: '_update_line_items'
          }
        }
      }

      commerce_call(:update_transaction, transaction)
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

    def commerce_client
      @commerce_client ||= client_api(@commerce_wsdl)
    end

    def security_client
      @security_client ||= client_api(@security_wsdl)
    end

    def client_api(wsdl)
      category = wsdl.include?('security') ? :security : :commerce

      client = Savon.client(
        wsdl: wsdl,
        endpoint: @endpoint,
        soap_header: headers(category),
        convert_request_keys_to: :none,
        pretty_print_xml: true
      )
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